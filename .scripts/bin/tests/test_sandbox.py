"""Tests for bin/sandbox.

The mount/environment/network/identity tests below launch the real thing -
pasta, bwrap, ssh-agent-guard, gh-guard, secret-service-guard, all of it - and
check what the sandboxed process actually sees. A source-text regex can only
tell you a flag is present; it can't tell you bwrap honored it, that a nested
namespace didn't reintroduce root, or that pasta's netns is actually reachable
- and that gap is exactly how the sandbox previously ran the sandboxed process
as uid 0 without any test catching it.

These need a real host: unprivileged user namespaces are unavailable from
inside an already-running bin/sandbox session (`--disable-userns` blocks
exactly that), so they skip themselves if run from in here. They also touch
real state - the host's ~/go/pkg and ~/go/bin, ~/.ide/<project>/ - so they
run against a throwaway git repo, not the dotfiles $HOME, and clean up the
~/.ide volume they create.

Structural properties that a normal end-to-end run doesn't exercise (trap
behavior under set -e/set -u when a guard fails early, word-splitting on
tracked filenames) are still checked against the source below.
"""

import hashlib
import os
import re
import shutil
import socket
import subprocess
import time
import uuid
from pathlib import Path

import pytest
from conftest import BIN_DIR

SANDBOX = BIN_DIR / "sandbox"
SOURCE = SANDBOX.read_text(encoding="utf-8")
CODE = "\n".join(line for line in SOURCE.splitlines() if not line.lstrip().startswith("#"))


# -- real sandbox execution --------------------------------------------------------


def _userns_usable():
    if shutil.which("bwrap") is None or shutil.which("pasta") is None:
        return False
    probe = subprocess.run(
        ["bwrap", "--unshare-all", "--unshare-user", "--disable-userns", "--ro-bind", "/", "/", "true"],
        capture_output=True,
        timeout=10,
    )
    return probe.returncode == 0


def run_sandbox(script, *, cwd, extra_env=None, timeout=60):
    """Feed `script` to the sandboxed bash's stdin, return the CompletedProcess.

    bin/sandbox's last arg is bare `bash`; with stdin not a tty, that reads and
    runs commands from it non-interactively (no .bashrc sourced) and exits at
    EOF, same as any other non-interactive bash script.
    """
    env = os.environ.copy()
    env.update(extra_env or {})
    return subprocess.run(
        [str(SANDBOX)],
        input=script,
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def _volume_name(repo):
    """Same derivation bin/sandbox uses, off git's own idea of the toplevel path -
    not `repo` itself, in case tmp_path involves a symlink git resolves away."""
    project = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    digest = hashlib.sha256(project.encode()).hexdigest()[:8]
    return project.replace("/", "_") + f"-{digest}"


@pytest.fixture
def project_dir(tmp_path):
    """A throwaway git repo, off the dotfiles-mode ($HOME) path bin/sandbox has."""
    if not _userns_usable():
        pytest.skip(
            "needs a real host: unprivileged user namespaces are unavailable here "
            "(e.g. this pytest run is itself inside bin/sandbox)"
        )
    repo = tmp_path / "project"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    yield repo
    shutil.rmtree(Path.home() / ".ide" / _volume_name(repo), ignore_errors=True)


# -- identity --------------------------------------------------------


def test_sandboxed_process_is_not_root(project_dir):
    """pasta's own user namespace maps the invoking user to uid 0 in it, same as
    `unshare -r` - without bwrap's --uid/--gid pinning it back, the sandboxed
    process looks like real root.
    """
    result = run_sandbox("id -u; id -g\n", cwd=project_dir)
    assert result.returncode == 0, result.stderr
    uid, gid = result.stdout.split()
    assert uid == str(os.getuid()), "sandboxed uid should be the real uid, not a namespace-mapped 0"
    assert gid == str(os.getgid())


# -- environment --------------------------------------------------------


def test_environment_is_cleared_and_reallowlisted(project_dir):
    """A GH_TOKEN inherited from the host shell would let sandboxed `gh` reach
    the API directly, walking straight around gh-guard's popup - the entire
    point of proxying gh to the host. --clearenv has to actually take effect,
    and the few vars usual development needs still have to come through.
    """
    result = run_sandbox(
        'echo "GH_TOKEN=[$GH_TOKEN]"\n'
        'echo "SOME_HOST_VAR=[$SOME_HOST_VAR]"\n'
        'echo "HOME=[$HOME]"\n'
        'echo "TERM=[$TERM]"\n',
        cwd=project_dir,
        extra_env={
            "GH_TOKEN": "leaked-token",
            "SOME_HOST_VAR": "should-not-cross",
            "TERM": "xterm-256color",
        },
    )
    assert result.returncode == 0, result.stderr
    assert "GH_TOKEN=[]" in result.stdout, "a host GH_TOKEN must never reach the sandbox"
    assert "SOME_HOST_VAR=[]" in result.stdout, "only allowlisted vars should survive --clearenv"
    assert f"HOME=[{os.environ['HOME']}]" in result.stdout
    assert "TERM=[xterm-256color]" in result.stdout, "TERM must pass through for terminal tools"


# -- mounts --------------------------------------------------------


def test_gh_client_shim_is_mounted_read_only(project_dir):
    """The shim and the host's own bin/gh-client are the same inode; a sandboxed
    write there is code execution on the host next time `gh` runs.
    """
    result = run_sandbox('echo x > "$XDG_RUNTIME_DIR/gh-shim/gh"\n', cwd=project_dir)
    assert result.returncode != 0
    assert "Read-only file system" in result.stderr


def test_claude_managed_settings_are_mounted_read_only(project_dir):
    """bin/claude-managed-settings.json must land at Claude Code's fixed managed-
    settings path so every sandbox inherits it (e.g. disabling the Claude-Session
    commit trailer) regardless of what the project's own .claude/ volume has -
    and it must not be writable from inside the sandbox.
    """
    expected = (BIN_DIR / "claude-managed-settings.json").read_text(encoding="utf-8")

    result = run_sandbox('cat /etc/claude-code/managed-settings.json\n', cwd=project_dir)
    assert result.returncode == 0, result.stderr
    assert result.stdout == expected

    result = run_sandbox('echo x > /etc/claude-code/managed-settings.json\n', cwd=project_dir)
    assert result.returncode != 0
    assert "Read-only file system" in result.stderr


def test_go_pkg_is_shared_but_go_bin_is_not(project_dir):
    """$HOME/go/pkg is the module cache: content-addressed and checksum-verified
    by the go tool, safe to share. $HOME/go/bin sits on the *host's* PATH ahead
    of every nix-store entry, so it must be a per-project volume instead - a
    file the sandbox writes there must never reach the real one.
    """
    home = Path.home()
    pkg_dir = home / "go" / "pkg"
    bin_dir = home / "go" / "bin"
    pkg_dir.mkdir(parents=True, exist_ok=True)
    bin_dir.mkdir(parents=True, exist_ok=True)

    shared_marker = f"test-shared-{uuid.uuid4().hex}"
    host_only_marker = f"test-host-only-{uuid.uuid4().hex}"
    sandbox_written_marker = f"test-from-sandbox-{uuid.uuid4().hex}"
    (pkg_dir / shared_marker).write_text("from host\n")
    (bin_dir / host_only_marker).write_text("from host\n")
    try:
        result = run_sandbox(
            f'test -f "$HOME/go/pkg/{shared_marker}" && echo PKG_VISIBLE\n'
            f'test -e "$HOME/go/bin/{host_only_marker}" && echo BIN_LEAKED || echo BIN_NOT_LEAKED\n'
            f'echo from sandbox > "$HOME/go/bin/{sandbox_written_marker}"\n',
            cwd=project_dir,
        )
        assert result.returncode == 0, result.stderr
        assert "PKG_VISIBLE" in result.stdout, "$HOME/go/pkg must be shared read-write into the sandbox"
        assert "BIN_NOT_LEAKED" in result.stdout, (
            "$HOME/go/bin must be a per-project volume, not the real host directory"
        )
        assert not (bin_dir / sandbox_written_marker).exists(), (
            "a file the sandbox wrote to $HOME/go/bin reached the real host directory"
        )
    finally:
        (pkg_dir / shared_marker).unlink(missing_ok=True)
        (bin_dir / host_only_marker).unlink(missing_ok=True)


def test_secrets_directory_is_locked_down():
    assert re.search(r'chmod 700 "\$\(dirname "\$secrets_db"\)"', CODE)


# -- networking --------------------------------------------------------


def test_network_is_reachable_through_pasta(project_dir):
    result = run_sandbox("getent hosts github.com\n", cwd=project_dir, timeout=30)
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip(), "pasta should still provide working DNS/outbound connectivity"


def test_abstract_x11_socket_is_not_reachable(project_dir):
    """The old --share-net exposed the host's abstract @/tmp/.X11-unix/X<n>
    socket to anything in the sandbox - Xwayland accepts unauthenticated local
    connections on it, so that was enough to drive XTEST against every X
    client on the desktop. pasta's own netns must not have that socket.
    """
    match = re.match(r":(\d+)", os.environ.get("DISPLAY", ""))
    if match is None:
        pytest.skip("no $DISPLAY on this host to check against")
    if shutil.which("python3") is None:
        pytest.skip("no python3 on this host to run the probe with")

    display_num = match.group(1)
    probe = (
        "python3 - <<'PYEOF'\n"
        "import socket\n"
        "s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)\n"
        "s.settimeout(2)\n"
        "try:\n"
        f"    s.connect('\\0/tmp/.X11-unix/X{display_num}')\n"
        "    print('CONNECTED')\n"
        "except OSError as e:\n"
        "    print('REFUSED', e)\n"
        "PYEOF\n"
    )
    result = run_sandbox(probe, cwd=project_dir)
    assert result.returncode == 0, result.stderr
    assert "CONNECTED" not in result.stdout, (
        "the sandbox can still reach the host's abstract X11 socket - "
        "--share-net is retaining the host's netns instead of pasta's"
    )


# -- cleanup --------------------------------------------------------


def _guard_pids():
    out = subprocess.run(
        ["pgrep", "-f", "ssh-agent-guard|gh-guard|secret-service-guard"],
        capture_output=True,
        text=True,
    ).stdout
    return set(out.split())


def test_guards_do_not_survive_the_sandbox_exiting(project_dir):
    before = _guard_pids()
    result = run_sandbox("true\n", cwd=project_dir)
    assert result.returncode == 0, result.stderr
    time.sleep(0.5)
    leaked = _guard_pids() - before
    assert not leaked, f"guard process(es) survived sandbox exit: {leaked}"


def _cleanup_body():
    match = re.search(r"function cleanup\(\) \{(.*?)\n\}", CODE, re.DOTALL)
    assert match, "expected a cleanup() function"
    return match.group(1)


def test_cleanup_variables_are_initialized_before_the_trap_is_installed():
    """Under `set -u`, a trap naming an unassigned variable aborts on the spot.

    The trap used to be installed before $gh_proxy_pid existed, so any early
    exit killed the trap instead of the guards - leaving them running and
    their temp dirs behind. A real run only exercises the happy path, so this
    stays a source check.
    """
    trap_line = next(i for i, line in enumerate(CODE.splitlines()) if line.startswith("trap "))
    body = _cleanup_body()
    # cleanup()'s own loop variables are scoped to it, not globals it inherits.
    locals_ = set(re.findall(r"\blocal\s+([\w\s]+)", body)[0].split())

    for var in sorted(set(re.findall(r"\$(\w+)", body)) - locals_):
        assignment = next(
            (i for i, line in enumerate(CODE.splitlines()) if line.startswith(f"{var}=")),
            None,
        )
        assert assignment is not None, f"${var} is used in cleanup() but never initialized"
        assert assignment < trap_line, f"${var} is initialized after the trap is installed"


def test_cleanup_variables_cover_every_guard_and_temp_dir():
    """A guard that isn't named in cleanup() outlives the sandbox that started it."""
    body = _cleanup_body()
    for var in ("agent_proxy", "secrets_bus", "secrets_guard", "gh_proxy"):
        assert f"${var}_pid" in body, f"cleanup() never kills ${var}_pid"
    for var in ("agent_proxy_dir", "secrets_dir", "gh_proxy_dir"):
        assert f"${var}" in body, f"cleanup() never removes ${var}"


def test_cleanup_survives_a_failing_kill():
    """Under `set -e`, an unguarded `kill` of an already-dead guard aborts the
    trap before it reaches the `rm -rf` - not reachable from a normal run,
    where every guard is still alive at exit."""
    assert re.search(r"kill \"\$pid\" 2>/dev/null \|\| true", _cleanup_body())


# -- tracked-file loops --------------------------------------------------------


def test_ls_tree_loops_are_nul_delimited():
    """These names become mount arguments; word splitting would mangle them."""
    assert "ls-tree" in CODE
    for invocation in re.findall(r"git -C \"\$HOME\" ls-tree[^\n)]*", CODE):
        assert " -z " in invocation, invocation
    assert "for f in $(" not in CODE
    assert len(re.findall(r"while IFS= read -r -d '' f; do", CODE)) == 2


# -- whole-file checks --------------------------------------------------------


def test_sandbox_is_syntactically_valid():
    subprocess.run(["bash", "-n", str(SANDBOX)], check=True)


def test_sandbox_passes_shellcheck():
    if shutil.which("shellcheck") is None:
        pytest.skip("shellcheck not installed")
    subprocess.run(["shellcheck", str(SANDBOX)], check=True)
