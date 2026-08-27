"""Shared test infra for bin/ scripts.

bin/*.py-style scripts have no .py extension and hyphenated names, so they
can't be `import`ed normally - load_module() imports one by file path instead.
"""

import importlib.machinery
import importlib.util
import struct
import sys
from pathlib import Path

BIN_DIR = Path(__file__).resolve().parent.parent


def load_module(filename):
    """Import a bin/<filename> script as a module and return it.

    Registered in sys.modules under a name derived from the filename before
    exec_module runs, since dbus_next's service decorators resolve type-hint
    strings against the module. The scripts' `if __name__ == "__main__":`
    guards mean main() never runs as a side effect of this import.
    """
    path = BIN_DIR / filename
    module_name = filename.replace("-", "_")
    # spec_from_file_location can't infer a loader for an extension-less
    # file, so hand it a SourceFileLoader explicitly.
    loader = importlib.machinery.SourceFileLoader(module_name, str(path))
    spec = importlib.util.spec_from_file_location(module_name, path, loader=loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def send_raw_frame(sock, frame_type, payload):
    """Send one (type-byte, 4-byte length, payload) frame - the gh-client/gh-guard wire format.

    Independent of the modules' own write_frame(), so tests exercising it
    aren't tautological.
    """
    sock.sendall(bytes([frame_type]) + struct.pack(">I", len(payload)) + payload)


def recv_raw_frame(sock):
    """Receive one (type-byte, 4-byte length, payload) frame.

    Returns None on a clean EOF before any header bytes arrive; raises
    ConnectionError if the peer closes mid-frame.
    """
    hdr = b""
    while len(hdr) < 5:
        chunk = sock.recv(5 - len(hdr))
        if not chunk:
            if hdr:
                raise ConnectionError("peer closed mid-header")
            return None
        hdr += chunk
    frame_type = hdr[0]
    (length,) = struct.unpack(">I", hdr[1:])
    payload = b""
    while len(payload) < length:
        chunk = sock.recv(length - len(payload))
        if not chunk:
            raise ConnectionError("peer closed mid-payload")
        payload += chunk
    return frame_type, payload
