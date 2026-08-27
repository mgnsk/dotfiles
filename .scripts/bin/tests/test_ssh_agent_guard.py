import base64
import hashlib
import os
import shlex
import socket
import struct
import subprocess
import tempfile
import threading

import pytest
from conftest import load_module

ssh_agent_guard = load_module("ssh-agent-guard")


@pytest.fixture
def sock_pair():
    a, b = socket.socketpair()
    yield a, b
    a.close()
    b.close()


@pytest.fixture(autouse=True)
def reset_identity_comments(monkeypatch):
    monkeypatch.setattr(ssh_agent_guard, "IDENTITY_COMMENTS", {})


# -- framing helpers --------------------------------------------------------


def test_write_frame_read_frame_roundtrip(sock_pair):
    a, b = sock_pair
    ssh_agent_guard.write_frame(a, b"payload")
    assert ssh_agent_guard.read_frame(b) == b"payload"


def test_read_frame_returns_none_on_close_before_header(sock_pair):
    a, b = sock_pair
    a.close()
    assert ssh_agent_guard.read_frame(b) is None


def test_read_frame_returns_none_on_close_mid_payload(sock_pair):
    a, b = sock_pair
    a.sendall(struct.pack(">I", 10) + b"abc")
    a.close()
    assert ssh_agent_guard.read_frame(b) is None


def test_recv_exact_returns_requested_bytes(sock_pair):
    a, b = sock_pair
    a.sendall(b"abcdef")
    assert ssh_agent_guard.recv_exact(b, 6) == b"abcdef"


def test_recv_exact_returns_none_on_early_close(sock_pair):
    a, b = sock_pair
    a.sendall(b"ab")
    a.close()
    assert ssh_agent_guard.recv_exact(b, 6) is None


# -- read_uint32 / read_string --------------------------------------------------------


def test_read_uint32():
    buf = struct.pack(">I", 42) + b"rest"
    value, offset = ssh_agent_guard.read_uint32(buf, 0)
    assert value == 42
    assert offset == 4


def test_read_string():
    buf = struct.pack(">I", 5) + b"hello" + b"tail"
    value, offset = ssh_agent_guard.read_string(buf, 0)
    assert value == b"hello"
    assert offset == 9


def test_read_string_length_exceeding_buffer_raises():
    buf = struct.pack(">I", 100) + b"short"
    with pytest.raises(struct.error):
        ssh_agent_guard.read_string(buf, 0)


# -- fingerprint --------------------------------------------------------


def test_fingerprint_matches_manual_sha256_base64():
    blob = b"fake-key-blob"
    digest = hashlib.sha256(blob).digest()
    expected = "SHA256:" + base64.b64encode(digest).decode("ascii").rstrip("=")
    assert ssh_agent_guard.fingerprint(blob) == expected


# -- cache_identities --------------------------------------------------------


def _identities_answer(pairs):
    body = struct.pack(">I", len(pairs))
    for key_blob, comment in pairs:
        body += struct.pack(">I", len(key_blob)) + key_blob
        body += struct.pack(">I", len(comment)) + comment
    return bytes([ssh_agent_guard.SSH_AGENT_IDENTITIES_ANSWER]) + body


def test_cache_identities_populates_by_fingerprint():
    payload = _identities_answer([(b"key1", b"comment1"), (b"key2", b"comment2")])

    ssh_agent_guard.cache_identities(payload)

    assert ssh_agent_guard.IDENTITY_COMMENTS[ssh_agent_guard.fingerprint(b"key1")] == "comment1"
    assert ssh_agent_guard.IDENTITY_COMMENTS[ssh_agent_guard.fingerprint(b"key2")] == "comment2"


def test_cache_identities_malformed_payload_is_swallowed():
    # Claims 5 keys but has no key/comment data to back that up.
    ssh_agent_guard.cache_identities(bytes([ssh_agent_guard.SSH_AGENT_IDENTITIES_ANSWER]) + struct.pack(">I", 5))

    assert ssh_agent_guard.IDENTITY_COMMENTS == {}


# -- peer_pid / peer_cwd / peer_cmdline / describe_peer ------------------------------------------


def _own_cmdline():
    with open(f"/proc/{os.getpid()}/cmdline", "rb") as f:
        raw = f.read()
    parts = raw.split(b"\0")
    if parts and parts[-1] == b"":
        parts.pop()
    return " ".join(shlex.quote(p.decode("utf-8", "replace")) for p in parts)


def test_peer_pid_returns_own_pid_over_same_process_socketpair(sock_pair):
    a, _b = sock_pair
    assert ssh_agent_guard.peer_pid(a) == os.getpid()


def test_peer_cwd_returns_real_cwd():
    assert ssh_agent_guard.peer_cwd(os.getpid()) == os.readlink(f"/proc/{os.getpid()}/cwd")


def test_peer_cwd_returns_unknown_for_dead_pid():
    # PID 0 never has a /proc entry, so the readlink fails the same way it
    # would for a peer that exited before we sampled it.
    assert ssh_agent_guard.peer_cwd(0) == "unknown"


def test_peer_cmdline_returns_real_cmdline():
    assert ssh_agent_guard.peer_cmdline(os.getpid()) == _own_cmdline()


def test_peer_cmdline_returns_unknown_on_oserror(monkeypatch):
    def raise_oserror(*_args, **_kwargs):
        raise OSError("boom")

    monkeypatch.setattr(ssh_agent_guard, "open", raise_oserror, raising=False)

    assert ssh_agent_guard.peer_cmdline(os.getpid()) == "unknown"


def test_describe_peer_returns_connect_time_cwd_and_cmdline(sock_pair):
    a, _b = sock_pair
    assert ssh_agent_guard.describe_peer(a) == (
        os.readlink(f"/proc/{os.getpid()}/cwd"),
        _own_cmdline(),
    )


def test_describe_peer_returns_unknown_when_peercred_fails(sock_pair, monkeypatch):
    a, _b = sock_pair

    def raise_oserror(*_args, **_kwargs):
        raise OSError("boom")

    monkeypatch.setattr(ssh_agent_guard, "peer_pid", raise_oserror)

    assert ssh_agent_guard.describe_peer(a) == ("unknown", "unknown")


# -- clean() --------------------------------------------------------


def test_clean_strips_nonprintable():
    assert ssh_agent_guard.clean("\x1b[31mred\x1b[0m") == "?[31mred?[0m"


def test_clean_truncates_long_strings():
    assert ssh_agent_guard.clean("a" * 250) == "a" * 200 + "…"


def test_clean_no_truncation_at_exact_limit():
    s = "a" * 200
    assert ssh_agent_guard.clean(s) == s


# -- confirm_via_tmux --------------------------------------------------------


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
    real_mkstemp = tempfile.mkstemp
    created = []

    def fake_mkstemp(prefix):
        fd, path = real_mkstemp(prefix=prefix, dir=str(tmp_path))
        created.append(path)
        return fd, path

    monkeypatch.setattr(ssh_agent_guard.tempfile, "mkstemp", fake_mkstemp)
    return created


def test_confirm_via_tmux_without_tmux_env_skips_popup(monkeypatch):
    monkeypatch.delenv("TMUX", raising=False)
    monkeypatch.setattr(
        subprocess, "Popen", lambda *a, **k: (_ for _ in ()).throw(AssertionError("no popup"))
    )
    assert ssh_agent_guard.confirm_via_tmux("/cwd", "ssh -T git@github.com", "id_ed25519") is False


def test_confirm_via_tmux_approved(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)

    def fake_popen(cmd, *a, **k):
        with open(created[0], "w", encoding="utf-8") as f:
            f.write("yes\n")
        return _FakePopup()

    monkeypatch.setattr(subprocess, "Popen", fake_popen)
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    assert ssh_agent_guard.confirm_via_tmux("/cwd", "git push", "id_ed25519") is True
    assert not os.path.exists(created[0])
    assert not os.path.exists(created[1])


def test_confirm_via_tmux_denied(monkeypatch, tmp_path):
    monkeypatch.setenv("TMUX", "session")
    created = _patch_tempfile_dir(monkeypatch, tmp_path)

    monkeypatch.setattr(subprocess, "Popen", lambda *a, **k: _FakePopup())
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: None)

    assert ssh_agent_guard.confirm_via_tmux("/cwd", "git push", "id_ed25519") is False
    assert not os.path.exists(created[0])
    assert not os.path.exists(created[1])


# -- handle_client() --------------------------------------------------------


def _sign_request(key_blob=b"fake-key"):
    return (
        bytes([ssh_agent_guard.SSH_AGENTC_SIGN_REQUEST])
        + struct.pack(">I", len(key_blob))
        + key_blob
    )


def _exchange(tmp_path, requests, upstream_replies=()):
    """Drive handle_client with `requests`, against a one-shot fake upstream agent.

    Returns (client_responses, upstream_seen). The fake upstream answers the
    first len(upstream_replies) frames it receives and then reads once more;
    that trailing read only returns - as None - when the guard tears the
    connection down, so a trailing None in upstream_seen is positive evidence
    that nothing further was forwarded to the real agent.

    Both threads are joined before returning, so upstream_seen is final and
    assertions run on the main thread.
    """
    upstream_path = str(tmp_path / "upstream.sock")
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(upstream_path)
    server.listen(1)
    upstream_seen = []

    def fake_upstream():
        conn, _ = server.accept()
        try:
            for reply in upstream_replies:
                upstream_seen.append(ssh_agent_guard.read_frame(conn))
                ssh_agent_guard.write_frame(conn, reply)
            upstream_seen.append(ssh_agent_guard.read_frame(conn))
        finally:
            conn.close()

    client, guard_side = socket.socketpair()
    upstream_thread = threading.Thread(target=fake_upstream, daemon=True)
    handler_thread = threading.Thread(
        target=ssh_agent_guard.handle_client, args=(guard_side, upstream_path), daemon=True
    )
    upstream_thread.start()
    handler_thread.start()

    responses = []
    try:
        for request in requests:
            ssh_agent_guard.write_frame(client, request)
            responses.append(ssh_agent_guard.read_frame(client))
    finally:
        client.close()
        handler_thread.join(timeout=2)
        upstream_thread.join(timeout=2)
        server.close()

    return responses, upstream_seen


def test_handle_client_forwards_identities_request_and_caches_response(tmp_path):
    request = bytes([ssh_agent_guard.SSH_AGENTC_REQUEST_IDENTITIES])
    answer = _identities_answer([(b"key1", b"comment1")])

    responses, upstream_seen = _exchange(tmp_path, [request], upstream_replies=[answer])

    assert upstream_seen == [request, None]
    assert responses == [answer]
    assert ssh_agent_guard.IDENTITY_COMMENTS[ssh_agent_guard.fingerprint(b"key1")] == "comment1"


def test_handle_client_sign_request_approved_forwards_to_upstream(tmp_path, monkeypatch):
    monkeypatch.setattr(ssh_agent_guard, "confirm_via_tmux", lambda *a, **k: True)
    signature = bytes([14]) + b"signature-bytes"

    responses, upstream_seen = _exchange(
        tmp_path, [_sign_request()], upstream_replies=[signature]
    )

    assert upstream_seen == [_sign_request(), None]
    assert responses == [signature]


def test_handle_client_sign_request_denied_never_reaches_upstream(tmp_path, monkeypatch):
    monkeypatch.setattr(ssh_agent_guard, "confirm_via_tmux", lambda *a, **k: False)

    responses, upstream_seen = _exchange(tmp_path, [_sign_request()])

    assert responses == [bytes([ssh_agent_guard.SSH_AGENT_FAILURE])]
    assert upstream_seen == [None]


@pytest.mark.parametrize(
    "msg_type",
    [
        17,  # ADD_IDENTITY
        18,  # REMOVE_IDENTITY
        19,  # REMOVE_ALL_IDENTITIES
        20,  # ADD_SMARTCARD_KEY
        21,  # REMOVE_SMARTCARD_KEY
        22,  # LOCK
        23,  # UNLOCK
        25,  # ADD_ID_CONSTRAINED
        26,  # ADD_SMARTCARD_KEY_CONSTRAINED
        27,  # EXTENSION
    ],
)
def test_handle_client_refuses_message_types_outside_the_allowlist(tmp_path, msg_type, monkeypatch):
    """Only identity listing and (gated) signing may reach the real agent.

    Everything else mutates agent state the sandbox has no business touching -
    LOCK in particular would wedge the user's agent outside the sandbox.
    """
    monkeypatch.setattr(
        ssh_agent_guard,
        "confirm_via_tmux",
        lambda *a, **k: pytest.fail("non-sign request reached the popup"),
    )

    responses, upstream_seen = _exchange(tmp_path, [bytes([msg_type]) + b"payload"])

    assert responses == [bytes([ssh_agent_guard.SSH_AGENT_FAILURE])]
    assert upstream_seen == [None]


def test_handle_client_samples_peer_once_at_connect(tmp_path, monkeypatch):
    """/proc is read when the peer connects, not per sign request.

    Sampling it later would let a peer that exited in the meantime have its
    pid reused by an unrelated host process, whose command line would then be
    what the popup blames the request on.
    """
    sampled = []
    monkeypatch.setattr(
        ssh_agent_guard,
        "describe_peer",
        lambda sock: (sampled.append(sock), ("/work", "git push"))[1],
    )
    prompts = []
    monkeypatch.setattr(
        ssh_agent_guard,
        "confirm_via_tmux",
        lambda cwd, cmdline, _comment: (prompts.append((cwd, cmdline)), True)[1],
    )
    signature = bytes([14]) + b"signature-bytes"

    responses, _upstream_seen = _exchange(
        tmp_path, [_sign_request(), _sign_request()], upstream_replies=[signature, signature]
    )

    assert responses == [signature, signature]
    assert len(sampled) == 1
    assert prompts == [("/work", "git push"), ("/work", "git push")]


def test_handle_client_upstream_connect_failure_closes_client(tmp_path):
    client, guard_side = socket.socketpair()
    nonexistent_path = str(tmp_path / "nope.sock")

    ssh_agent_guard.handle_client(guard_side, nonexistent_path)

    assert client.recv(1) == b""
    client.close()
