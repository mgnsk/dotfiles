import io
import json
import os
import socket
import struct
import subprocess
import tempfile
import threading

import pytest
from conftest import load_module, recv_raw_frame, send_raw_frame

gh_guard = load_module("gh-guard")


@pytest.fixture
def sock_pair():
    a, b = socket.socketpair()
    yield a, b
    a.close()
    b.close()


def _write(sock, frame_type, payload):
    gh_guard.write_frame(sock, threading.Lock(), frame_type, payload)


# -- framing helpers --------------------------------------------------------


def test_write_frame_read_frame_roundtrip(sock_pair):
    a, b = sock_pair
    _write(a, gh_guard.HEADER, b"payload")
    frame_type, payload = gh_guard.read_frame(b)
    assert frame_type == gh_guard.HEADER
    assert payload == b"payload"


def test_read_frame_returns_none_on_close_before_header(sock_pair):
    a, b = sock_pair
    a.close()
    assert gh_guard.read_frame(b) is None


def test_read_frame_returns_none_on_close_mid_payload(sock_pair):
    a, b = sock_pair
    a.sendall(bytes([gh_guard.HEADER]) + struct.pack(">I", 10) + b"abc")
    a.close()
    assert gh_guard.read_frame(b) is None


def test_read_frame_rejects_oversized_header_without_blocking_on_payload(sock_pair):
    """A HEADER's length prefix is attacker-controlled (this socket is reachable by
    anything in the sandbox); claiming ~4 GiB must not make gh-guard try to buffer it."""
    a, b = sock_pair
    a.sendall(bytes([gh_guard.HEADER]) + struct.pack(">I", gh_guard.MAX_HEADER_SIZE + 1))
    assert gh_guard.read_frame(b) is None


def test_read_frame_rejects_oversized_non_header_frame(sock_pair):
    a, b = sock_pair
    a.sendall(bytes([gh_guard.STDIN_CHUNK]) + struct.pack(">I", gh_guard.MAX_FRAME_SIZE + 1))
    assert gh_guard.read_frame(b) is None


def test_read_frame_accepts_header_at_the_size_limit(sock_pair):
    """A payload this size overflows the socketpair's buffer, so the send must run
    concurrently with the read - sendall would otherwise block on a full buffer forever."""
    a, b = sock_pair
    payload = b"x" * gh_guard.MAX_HEADER_SIZE
    sender = threading.Thread(
        target=a.sendall, args=(bytes([gh_guard.HEADER]) + struct.pack(">I", len(payload)) + payload,)
    )
    sender.start()
    frame_type, received = gh_guard.read_frame(b)
    sender.join(timeout=5)
    assert frame_type == gh_guard.HEADER
    assert received == payload


def test_recv_exact_returns_requested_bytes(sock_pair):
    a, b = sock_pair
    a.sendall(b"abcdef")
    assert gh_guard.recv_exact(b, 6) == b"abcdef"


def test_recv_exact_returns_none_on_early_close(sock_pair):
    a, b = sock_pair
    a.sendall(b"ab")
    a.close()
    assert gh_guard.recv_exact(b, 6) is None


# -- clean() --------------------------------------------------------


def test_clean_strips_nonprintable():
    assert gh_guard.clean("\x1b[31mred\x1b[0m") == "?[31mred?[0m"


def test_clean_does_not_truncate_long_strings():
    """A crafted argv shouldn't be able to hide its tail past some display cutoff -
    what's shown must be exactly what gets executed."""
    s = "a" * 5000
    assert gh_guard.clean(s) == s


# -- build_gh_env() --------------------------------------------------------


def test_build_gh_env_drops_non_whitelisted_keys(monkeypatch):
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    env = gh_guard.build_gh_env(False, None, {"PATH": "/evil", "NO_COLOR": "1"})
    assert env["NO_COLOR"] == "1"
    assert env["PATH"] == os.environ["PATH"]


def test_build_gh_env_sets_force_tty_from_columns(monkeypatch):
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    env = gh_guard.build_gh_env(True, 80, {})
    assert env["GH_FORCE_TTY"] == "80"


def test_build_gh_env_sets_force_tty_1_without_columns(monkeypatch):
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    env = gh_guard.build_gh_env(True, None, {})
    assert env["GH_FORCE_TTY"] == "1"


def test_build_gh_env_respects_explicit_override(monkeypatch):
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    env = gh_guard.build_gh_env(True, 80, {"GH_FORCE_TTY": "0"})
    assert env["GH_FORCE_TTY"] == "0"


def test_build_gh_env_no_force_tty_when_not_isatty(monkeypatch):
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    env = gh_guard.build_gh_env(False, None, {})
    assert "GH_FORCE_TTY" not in env


# -- confirm_via_tmux() --------------------------------------------------------


class _FakePopup:
    def __init__(self, returncode=0):
        self.returncode = returncode

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def wait(self):
        return self.returncode


def _patch_tempfile_dir(monkeypatch, tmp_path):
    """Make confirm_via_tmux's marker/info tempfiles land under tmp_path, in order."""
    real_mkstemp = tempfile.mkstemp
    created = []

    def fake_mkstemp(prefix):
        fd, path = real_mkstemp(prefix=prefix, dir=str(tmp_path))
        created.append(path)
        return fd, path

    monkeypatch.setattr(gh_guard.tempfile, "mkstemp", fake_mkstemp)
    return created


def test_confirm_via_tmux_without_tmux_env_skips_popup(monkeypatch):
    monkeypatch.delenv("TMUX", raising=False)
    monkeypatch.setattr(
        subprocess, "Popen", lambda *a, **k: (_ for _ in ()).throw(AssertionError("no popup"))
    )
    assert gh_guard.confirm_via_tmux("/cwd", ["pr", "status"]) is False


def test_confirm_via_tmux_approved_reads_yes_marker(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)

    def fake_popen(cmd, *a, **k):
        marker_path = created[0]
        with open(marker_path, "w", encoding="utf-8") as f:
            f.write("yes\n")
        return _FakePopup()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    assert gh_guard.confirm_via_tmux("/cwd", ["pr", "status"]) is True
    assert not os.path.exists(created[0])
    assert not os.path.exists(created[1])


def test_confirm_via_tmux_denied_leaves_marker_empty(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)

    monkeypatch.setattr(subprocess, "Popen", lambda *a, **k: _FakePopup())
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    assert gh_guard.confirm_via_tmux("/cwd", ["pr", "status"]) is False
    assert not os.path.exists(created[0])
    assert not os.path.exists(created[1])


def test_confirm_via_tmux_info_text_includes_cwd_and_command(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)
    seen_info_text = {}

    def fake_popen(cmd, *a, **k):
        info_path = created[1]
        with open(info_path, encoding="utf-8") as f:
            seen_info_text["text"] = f.read()
        return _FakePopup()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    gh_guard.confirm_via_tmux("/my/project", ["issue", "create", "--title", "test with spaces"])
    text = seen_info_text["text"]
    assert "cwd:      /my/project" in text
    assert "command:  gh issue create --title 'test with spaces'" in text


def test_confirm_via_tmux_info_text_handles_empty_argv(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)
    seen_info_text = {}

    def fake_popen(cmd, *a, **k):
        info_path = created[1]
        with open(info_path, encoding="utf-8") as f:
            seen_info_text["text"] = f.read()
        return _FakePopup()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    gh_guard.confirm_via_tmux("/my/project", [])
    text = seen_info_text["text"]
    assert "cwd:      /my/project" in text
    assert "command:  gh\n" in text


# -- parse_header() --------------------------------------------------------


def _header(cwd="/tmp", argv=None, isatty=False, columns=None, env=None):
    return json.dumps(
        {
            "cwd": cwd,
            "argv": argv or [],
            "isatty": isatty,
            "columns": columns,
            "env": env or {},
        }
    ).encode()


def test_parse_header_accepts_a_well_formed_header():
    payload = _header(cwd="/tmp/work", argv=["pr", "status"], isatty=True, columns=80,
                      env={"NO_COLOR": "1"})
    assert gh_guard.parse_header(payload) == ("/tmp/work", ["pr", "status"], True, 80,
                                              {"NO_COLOR": "1"})


def test_parse_header_defaults_optional_fields():
    payload = json.dumps({"cwd": "/tmp", "argv": []}).encode()
    assert gh_guard.parse_header(payload) == ("/tmp", [], False, None, {})


@pytest.mark.parametrize("env", [["PATH=/evil"], "PATH=/evil", None, 7])
def test_parse_header_drops_a_non_dict_env(env):
    """build_gh_env expects a mapping; anything else would blow up mid-merge."""
    payload = json.dumps({"cwd": "/tmp", "argv": [], "env": env}).encode()
    assert gh_guard.parse_header(payload)[4] == {}


@pytest.mark.parametrize(
    "header",
    [
        pytest.param({"argv": []}, id="missing-cwd"),
        pytest.param({"cwd": "/tmp"}, id="missing-argv"),
        pytest.param({"cwd": 1, "argv": []}, id="non-string-cwd"),
        pytest.param({"cwd": "/tmp", "argv": "pr"}, id="argv-not-a-list"),
        pytest.param({"cwd": "/tmp", "argv": ["pr", 2]}, id="non-string-argv-entry"),
        pytest.param({"cwd": "/tmp", "argv": [], "isatty": "yes"}, id="string-isatty"),
        pytest.param({"cwd": "/tmp", "argv": [], "isatty": 1}, id="int-isatty"),
        pytest.param({"cwd": "/tmp", "argv": [], "columns": "80"}, id="string-columns"),
        pytest.param({"cwd": "/tmp", "argv": [], "columns": 0}, id="zero-columns"),
        pytest.param({"cwd": "/tmp", "argv": [], "columns": -1}, id="negative-columns"),
        pytest.param({"cwd": "/tmp", "argv": [], "columns": True}, id="bool-columns"),
        pytest.param({"cwd": "/tmp", "argv": [], "columns": {}}, id="dict-columns"),
    ],
)
def test_parse_header_rejects_malformed_headers(header):
    with pytest.raises((ValueError, KeyError)):
        gh_guard.parse_header(json.dumps(header).encode())


def test_parse_header_rejects_non_json():
    with pytest.raises(json.JSONDecodeError):
        gh_guard.parse_header(b"not json")


# -- cwd_is_contained() --------------------------------------------------------


def test_cwd_is_contained_accepts_root_itself():
    assert gh_guard.cwd_is_contained("/tmp/proj", "/tmp/proj") is True


def test_cwd_is_contained_accepts_subdirectory():
    assert gh_guard.cwd_is_contained("/tmp/proj/sub/dir", "/tmp/proj") is True


def test_cwd_is_contained_rejects_sibling_directory():
    """A sibling with the root as a string prefix (/tmp/proj-evil vs /tmp/proj) must not
    pass a naive startswith check."""
    assert gh_guard.cwd_is_contained("/tmp/proj-evil", "/tmp/proj") is False


def test_cwd_is_contained_rejects_unrelated_path():
    assert gh_guard.cwd_is_contained("/home/other/repo", "/tmp/proj") is False


def test_cwd_is_contained_resolves_dotdot_escape():
    assert gh_guard.cwd_is_contained("/tmp/proj/../../etc", "/tmp/proj") is False


# -- handle_connection() --------------------------------------------------------

# Matches the default cwd ("/tmp") in _header() and the "/tmp/work" used by a
# few tests below - handle_connection now refuses any cwd outside the project
# root it's given, so tests not exercising that check need one that contains
# their header's cwd.
PROJECT_ROOT = "/tmp"


class _FD:
    def __init__(self, fd):
        self._fd = fd

    def fileno(self):
        return self._fd


class _FakeProcess:
    def __init__(self, stdout_data=b"", stderr_data=b"", returncode=0):
        self.returncode = returncode
        self.args = None
        stdout_r, stdout_w = os.pipe()
        os.write(stdout_w, stdout_data)
        os.close(stdout_w)
        stderr_r, stderr_w = os.pipe()
        os.write(stderr_w, stderr_data)
        os.close(stderr_w)
        self._read_fds = (stdout_r, stderr_r)
        self.stdout = _FD(stdout_r)
        self.stderr = _FD(stderr_r)
        self.stdin = io.BytesIO()

    def wait(self):
        return self.returncode

    def poll(self):
        return self.returncode

    def close(self):
        for fd in self._read_fds:
            os.close(fd)


def test_handle_connection_approved_runs_gh_and_relays_output_and_exit_code(monkeypatch):
    monkeypatch.setattr(gh_guard, "confirm_via_tmux", lambda cwd, argv: True)

    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.HEADER, _header(cwd="/tmp/work", argv=["pr", "status"]))

    fake_process = _FakeProcess(stdout_data=b"out-data", stderr_data=b"err-data", returncode=3)
    popen_calls = []

    def fake_popen(cmd, **kwargs):
        popen_calls.append((cmd, kwargs))
        return fake_process

    monkeypatch.setattr(subprocess, "Popen", fake_popen)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)

        frames = []
        while True:
            frame = recv_raw_frame(theirs)
            if frame is None:
                break
            frames.append(frame)
    finally:
        fake_process.close()
        theirs.close()

    assert set(frames[:-1]) == {
        (gh_guard.STDOUT_CHUNK, b"out-data"),
        (gh_guard.STDERR_CHUNK, b"err-data"),
    }
    assert frames[-1] == (gh_guard.EXIT_CODE, struct.pack(">I", 3))
    [(cmd, kwargs)] = popen_calls
    assert cmd == ["gh", "pr", "status"]
    assert kwargs["cwd"] == "/tmp/work"


def test_handle_connection_denied_sends_denied_frame_and_never_spawns_gh(monkeypatch):
    monkeypatch.setattr(gh_guard, "confirm_via_tmux", lambda cwd, argv: False)

    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.HEADER, _header(cwd="/tmp/work", argv=["pr", "status"]))

    popen_called = False

    def fake_popen(cmd, **kwargs):
        nonlocal popen_called
        popen_called = True
        return _FakeProcess()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)

        frame = recv_raw_frame(theirs)
        assert frame is not None
        frame_type, payload = frame
        assert frame_type == gh_guard.DENIED
        assert b"declined" in payload
        assert recv_raw_frame(theirs) is None
    finally:
        theirs.close()

    assert not popen_called


def test_handle_connection_rejects_cwd_outside_project_root_without_prompting(monkeypatch):
    confirm_called = False

    def fake_confirm(cwd, argv):
        nonlocal confirm_called
        confirm_called = True
        return True

    monkeypatch.setattr(gh_guard, "confirm_via_tmux", fake_confirm)

    ours, theirs = socket.socketpair()
    send_raw_frame(
        theirs, gh_guard.HEADER, _header(cwd="/somewhere/else", argv=["pr", "status"])
    )

    popen_called = False

    def fake_popen(cmd, **kwargs):
        nonlocal popen_called
        popen_called = True
        return _FakeProcess()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)

        frame = recv_raw_frame(theirs)
        assert frame is not None
        frame_type, payload = frame
        assert frame_type == gh_guard.DENIED
        assert b"outside the sandboxed project" in payload
        assert recv_raw_frame(theirs) is None
    finally:
        theirs.close()

    assert not confirm_called, "must refuse before ever asking the user to approve"
    assert not popen_called


def test_handle_connection_forwards_tty_hints_from_a_valid_header(monkeypatch):
    monkeypatch.setattr(gh_guard, "confirm_via_tmux", lambda cwd, argv: True)
    monkeypatch.delenv("GH_FORCE_TTY", raising=False)
    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.HEADER, _header(argv=["pr", "list"], isatty=True, columns=80))

    fake_process = _FakeProcess()
    popen_calls = []

    def fake_popen(cmd, **kwargs):
        popen_calls.append((cmd, kwargs))
        return fake_process

    monkeypatch.setattr(subprocess, "Popen", fake_popen)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)
    finally:
        fake_process.close()
        theirs.close()

    [(_cmd, kwargs)] = popen_calls
    assert kwargs["env"]["GH_FORCE_TTY"] == "80"


def test_handle_connection_popen_oserror_sends_denied_frame(monkeypatch):
    monkeypatch.setattr(gh_guard, "confirm_via_tmux", lambda cwd, argv: True)
    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.HEADER, _header(argv=["pr", "status"]))

    def fake_popen(*a, **k):
        raise OSError("binary not found")

    monkeypatch.setattr(subprocess, "Popen", fake_popen)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)
        frame = recv_raw_frame(theirs)
        assert frame is not None
        frame_type, payload = frame
        assert frame_type == gh_guard.DENIED
        assert b"failed to start gh" in payload
    finally:
        theirs.close()


def test_handle_connection_rejects_non_header_first_frame(monkeypatch):
    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.STDIN_CHUNK, _header(argv=["pr", "status"]))

    monkeypatch.setattr(
        subprocess, "Popen", lambda *a, **k: (_ for _ in ()).throw(AssertionError("rejected"))
    )

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)
        assert recv_raw_frame(theirs) is None
    finally:
        theirs.close()


@pytest.mark.parametrize(
    "field, value",
    [
        ("isatty", "yes"),
        ("isatty", 1),
        ("isatty", None),
        ("columns", "80"),
        ("columns", 0),
        ("columns", -1),
        ("columns", True),
        ("columns", {}),
    ],
)
def test_handle_connection_rejects_malformed_tty_hints(field, value, monkeypatch):
    ours, theirs = socket.socketpair()
    send_raw_frame(theirs, gh_guard.HEADER, _header(**{field: value}))

    monkeypatch.setattr(
        subprocess, "Popen", lambda *a, **k: (_ for _ in ()).throw(AssertionError("rejected"))
    )

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)
        assert recv_raw_frame(theirs) is None
    finally:
        theirs.close()


def test_handle_connection_malformed_header_closes_quietly():
    ours, theirs = socket.socketpair()
    bad_header = json.dumps({"argv": ["pr"]}).encode()  # missing "cwd"
    send_raw_frame(theirs, gh_guard.HEADER, bad_header)

    try:
        gh_guard.handle_connection(ours, PROJECT_ROOT)
        assert recv_raw_frame(theirs) is None
    finally:
        theirs.close()


# -- kill_process_group() --------------------------------------------------------


def test_kill_process_group_terminates_real_process():
    process = subprocess.Popen(["sleep", "5"], start_new_session=True)
    gh_guard.kill_process_group(process)
    process.wait(timeout=2)
    assert process.poll() is not None


# -- relay_output() / relay_stdin() ---------------------------------------------


def test_relay_output_forwards_pipe_bytes_to_socket(sock_pair):
    a, b = sock_pair
    r, w = os.pipe()
    os.write(w, b"hello from pipe")
    os.close(w)
    lock = threading.Lock()

    t = threading.Thread(target=gh_guard.relay_output, args=(r, a, lock, gh_guard.STDOUT_CHUNK))
    t.start()
    t.join(timeout=2)
    os.close(r)

    frame_type, payload = gh_guard.read_frame(b)
    assert frame_type == gh_guard.STDOUT_CHUNK
    assert payload == b"hello from pipe"


def test_relay_stdin_forwards_chunks_and_closes_on_eof(sock_pair):
    a, b = sock_pair

    class MockStdin:
        def __init__(self):
            self.data = bytearray()
            self.closed = False

        def write(self, chunk):
            self.data.extend(chunk)

        def close(self):
            self.closed = True

    class MockProcess:
        def __init__(self):
            self.stdin = MockStdin()
            self.pid = 12345

        def poll(self):
            return 0

    proc = MockProcess()
    t = threading.Thread(target=gh_guard.relay_stdin, args=(b, proc))
    t.start()

    _write(a, gh_guard.STDIN_CHUNK, b"chunk1")
    _write(a, gh_guard.STDIN_CHUNK, b"chunk2")
    _write(a, gh_guard.STDIN_EOF, b"")

    t.join(timeout=2)
    assert proc.stdin.data == b"chunk1chunk2"
    assert proc.stdin.closed is True


def test_relay_stdin_kills_process_group_on_unexpected_client_disconnect(sock_pair, monkeypatch):
    a, b = sock_pair

    class MockProcess:
        def __init__(self):
            self.stdin = io.BytesIO()
            self.pid = 99999

        def poll(self):
            return None

    proc = MockProcess()
    killed = False

    def fake_kill(p):
        nonlocal killed
        killed = True

    monkeypatch.setattr(gh_guard, "kill_process_group", fake_kill)

    t = threading.Thread(target=gh_guard.relay_stdin, args=(b, proc))
    t.start()

    a.close()  # Close socket before STDIN_EOF
    t.join(timeout=2)

    assert killed is True
