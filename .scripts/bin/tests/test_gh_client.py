import io
import json
import os
import socket
import struct
import sys
import threading

import pytest
from conftest import load_module, recv_raw_frame, send_raw_frame

gh_client = load_module("gh-client")


@pytest.fixture
def sock_pair():
    a, b = socket.socketpair()
    yield a, b
    a.close()
    b.close()


# -- framing helpers --------------------------------------------------------


def test_write_frame_read_frame_roundtrip(sock_pair):
    a, b = sock_pair
    gh_client.write_frame(a, gh_client.HEADER, b"payload")
    frame_type, payload = gh_client.read_frame(b)
    assert frame_type == gh_client.HEADER
    assert payload == b"payload"


def test_write_frame_wire_format(sock_pair):
    a, b = sock_pair
    gh_client.write_frame(a, gh_client.STDOUT_CHUNK, b"hi")
    frame_type, payload = recv_raw_frame(b)
    assert frame_type == gh_client.STDOUT_CHUNK
    assert payload == b"hi"


def test_read_frame_returns_none_on_close_before_header(sock_pair):
    a, b = sock_pair
    a.close()
    assert gh_client.read_frame(b) is None


def test_read_frame_returns_none_on_close_mid_payload(sock_pair):
    a, b = sock_pair
    a.sendall(bytes([gh_client.HEADER]) + struct.pack(">I", 10) + b"abc")
    a.close()
    assert gh_client.read_frame(b) is None


def test_recv_exact_returns_requested_bytes(sock_pair):
    a, b = sock_pair
    a.sendall(b"abcdef")
    assert gh_client.recv_exact(b, 6) == b"abcdef"


def test_recv_exact_returns_none_on_early_close(sock_pair):
    a, b = sock_pair
    a.sendall(b"ab")
    a.close()
    assert gh_client.recv_exact(b, 6) is None


# -- relay_stdin --------------------------------------------------------


def test_relay_stdin_forwards_chunks_then_eof(monkeypatch):
    reads = iter([b"abc", b"def", b""])
    monkeypatch.setattr(gh_client.os, "read", lambda fd, n: next(reads))
    written = []
    monkeypatch.setattr(gh_client, "write_frame", lambda sock, t, p: written.append((t, p)))

    gh_client.relay_stdin(object())

    assert written == [
        (gh_client.STDIN_CHUNK, b"abc"),
        (gh_client.STDIN_CHUNK, b"def"),
        (gh_client.STDIN_EOF, b""),
    ]


# -- main() integration --------------------------------------------------------


@pytest.fixture
def eof_stdin():
    """Point real fd 0 at an already-closed pipe so relay_stdin's os.read(0, ...) sees EOF."""
    r, w = os.pipe()
    os.close(w)
    saved = os.dup(0)
    os.dup2(r, 0)
    os.close(r)
    yield
    os.dup2(saved, 0)
    os.close(saved)


def _patch_streams(monkeypatch):
    """Replace sys.stdout/stderr with BytesIO-backed fakes gh_client.main() can write to.

    Deliberately called from inside the test body rather than as a fixture:
    pytest's capture manager resumes its own stdout/stderr capture when
    transitioning from fixture setup into the test call phase, which would
    clobber a patch applied during fixture setup.
    """
    stdout = io.TextIOWrapper(io.BytesIO(), write_through=True)
    stderr = io.TextIOWrapper(io.BytesIO(), write_through=True)
    monkeypatch.setattr(sys, "stdout", stdout)
    monkeypatch.setattr(sys, "stderr", stderr)
    return stdout, stderr


def _run_guard_server(sock_path, respond):
    """Accept one connection, read the HEADER frame, then let `respond` reply.

    Returns (thread, state) where state["header"]/state["error"] are filled in
    after thread.join() - assertions on them must happen on the main thread,
    since an AssertionError raised inside `serve` would otherwise just be
    swallowed by the thread.
    """
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(sock_path))
    server.listen(1)
    state = {}

    def serve():
        try:
            conn, _ = server.accept()
            frame_type, payload = recv_raw_frame(conn)
            if frame_type != gh_client.HEADER:
                raise AssertionError(f"expected HEADER, got {frame_type}")
            state["header"] = json.loads(payload)
            respond(conn, payload)
            conn.close()
        except Exception as e:  # noqa: BLE001 - surfaced via state["error"]
            state["error"] = e
        finally:
            server.close()

    thread = threading.Thread(target=serve, daemon=True)
    thread.start()
    return thread, state


def test_main_relays_stdout_stderr_and_exit_code(tmp_path, monkeypatch, eof_stdin):
    stdout, stderr = _patch_streams(monkeypatch)
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path))
    monkeypatch.setattr(sys, "argv", ["gh-client", "pr", "status"])

    def respond(conn, _header_payload):
        send_raw_frame(conn, gh_client.STDOUT_CHUNK, b"hello stdout")
        send_raw_frame(conn, gh_client.STDERR_CHUNK, b"hello stderr")
        send_raw_frame(conn, gh_client.EXIT_CODE, struct.pack(">I", 7))

    thread, state = _run_guard_server(tmp_path / "gh-guard.sock", respond)

    with pytest.raises(SystemExit) as exc_info:
        gh_client.main()
    thread.join(timeout=2)

    assert "error" not in state, state.get("error")
    assert state["header"]["argv"] == ["pr", "status"]
    assert exc_info.value.code == 7
    assert stdout.buffer.getvalue() == b"hello stdout"
    assert stderr.buffer.getvalue() == b"hello stderr"


def test_main_denied_exits_1_with_message(tmp_path, monkeypatch, eof_stdin):
    _stdout, stderr = _patch_streams(monkeypatch)
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path))
    monkeypatch.setattr(sys, "argv", ["gh-client", "pr", "status"])

    def respond(conn, _header_payload):
        send_raw_frame(conn, gh_client.DENIED, b"gh-guard: access declined\n")

    thread, state = _run_guard_server(tmp_path / "gh-guard.sock", respond)

    with pytest.raises(SystemExit) as exc_info:
        gh_client.main()
    thread.join(timeout=2)

    assert "error" not in state, state.get("error")
    assert exc_info.value.code == 1
    assert "access declined" in stderr.buffer.getvalue().decode()
