"""Unit tests for bin/secret-service-guard's Store and D-Bus interface classes.

No real D-Bus bus is used anywhere here - CollectionIface takes a fake bus
stub, and @method-decorated methods are called through their raw underlying
function (see _raw()) rather than the dbus_next-wrapped one, since dbus_next's
@method wrapper discards the Python return value (real dispatch reads
_Method.fn directly instead of calling through the wrapper - see
dbus_next.service.method/ServiceInterface).
"""

import os
import stat

from dbus_next import Variant

import pytest
from conftest import load_module

ss = load_module("secret-service-guard")


def _mode(path):
    return stat.S_IMODE(os.stat(path).st_mode)


def _raw(class_method):
    """Return the undecorated function behind an @method-decorated class method."""
    return class_method.__dict__["__DBUS_METHOD"].fn


class FakeBus:
    def __init__(self):
        self.exported = {}

    def export(self, path, iface):
        self.exported[path] = iface


@pytest.fixture
def store(tmp_path):
    return ss.Store(str(tmp_path / "secrets.sqlite3"))


# -- Store --------------------------------------------------------


def test_store_upsert_and_get(store):
    row_id = store.upsert("label", {"service": "gh"}, "text/plain", b"secret1", replace=False)
    content_type, secret = store.get(row_id)
    assert content_type == "text/plain"
    assert secret == b"secret1"


def test_store_find_by_attributes_requires_exact_match(store):
    row_id = store.upsert(
        "label", {"service": "gh", "account": "me"}, "text/plain", b"x", replace=False
    )
    assert store.find_by_attributes({"service": "gh", "account": "me"}) == row_id
    assert store.find_by_attributes({"service": "gh"}) is None
    assert store.find_by_attributes({"service": "gh", "account": "someone-else"}) is None


def test_store_upsert_replace_updates_in_place(store):
    attrs = {"service": "gh"}
    id1 = store.upsert("label1", attrs, "text/plain", b"old", replace=True)
    id2 = store.upsert("label2", attrs, "text/plain", b"new", replace=True)
    assert id1 == id2
    assert len(store.all_rows()) == 1
    content_type, secret = store.get(id1)
    assert content_type == "text/plain"
    assert secret == b"new"


def test_store_upsert_without_replace_inserts_duplicate(store):
    attrs = {"service": "gh"}
    id1 = store.upsert("label1", attrs, "text/plain", b"old", replace=False)
    id2 = store.upsert("label2", attrs, "text/plain", b"new", replace=False)
    assert id1 != id2
    assert len(store.all_rows()) == 2


def test_store_get_missing_raises_keyerror(store):
    with pytest.raises(KeyError):
        store.get(999)


def test_store_delete(store):
    row_id = store.upsert("label", {"service": "gh"}, "text/plain", b"x", replace=False)
    store.delete(row_id)
    assert store.all_rows() == []
    with pytest.raises(KeyError):
        store.get(row_id)


def test_store_all_rows_round_trips_attributes_and_secret_bytes(store):
    row_id = store.upsert("mylabel", {"a": "1", "b": "2"}, "text/plain", b"payload", replace=False)
    [(rid, label, attrs, content_type, secret)] = store.all_rows()
    assert rid == row_id
    assert label == "mylabel"
    assert attrs == {"a": "1", "b": "2"}
    assert content_type == "text/plain"
    assert secret == b"payload"
    assert isinstance(secret, bytes)


def test_item_path_format():
    assert ss.item_path(5) == f"{ss.ITEM_PATH_PREFIX}5"


# -- Store file permissions --------------------------------------------------------


def test_store_creates_db_owner_readable_only(tmp_path):
    """The database holds credentials in plaintext; the default umask would make it 0644."""
    path = tmp_path / "secrets.sqlite3"
    ss.Store(str(path))
    assert _mode(path) == 0o600


def test_store_tightens_permissions_on_a_preexisting_db(tmp_path):
    """Databases created before this was enforced get fixed on the next open."""
    path = tmp_path / "secrets.sqlite3"
    path.touch(mode=0o644)
    os.chmod(path, 0o644)  # touch() honours the umask; this doesn't

    ss.Store(str(path))

    assert _mode(path) == 0o600


def test_store_wal_sidecar_is_owner_readable_only(tmp_path):
    """SQLite copies the database file's mode onto -wal/-shm, so those follow along."""
    path = tmp_path / "secrets.sqlite3"
    store = ss.Store(str(path))
    store.upsert("label", {"service": "gh"}, "text/plain", b"topsecret", replace=False)

    wal = tmp_path / "secrets.sqlite3-wal"
    assert wal.exists()
    assert _mode(wal) == 0o600


# -- ServiceIface --------------------------------------------------------


def test_service_iface_open_session_increments_session_path():
    service = ss.ServiceIface()
    _algo1, path1 = _raw(ss.ServiceIface.open_session)(service, "plain", None)
    _algo2, path2 = _raw(ss.ServiceIface.open_session)(service, "plain", None)
    assert path1 == "/org/freedesktop/secrets/session/s1"
    assert path2 == "/org/freedesktop/secrets/session/s2"


def test_service_iface_unlock_always_succeeds_with_no_prompt():
    service = ss.ServiceIface()
    objects, prompt = _raw(ss.ServiceIface.unlock)(service, ["/some/obj"])
    assert objects == ["/some/obj"]
    assert prompt == ss.NULL_PATH


def test_service_iface_collections_always_empty():
    assert ss.ServiceIface().collections == []


# -- ItemIface --------------------------------------------------------


def test_item_iface_get_secret(store):
    row_id = store.upsert("label", {"service": "gh"}, "text/plain", b"topsecret", replace=False)
    item = ss.ItemIface(store, row_id)

    result = _raw(ss.ItemIface.get_secret)(item, "/session/s1")

    assert result == ["/session/s1", b"", b"topsecret", "text/plain"]


def test_item_iface_delete_removes_from_store(store):
    row_id = store.upsert("label", {"service": "gh"}, "text/plain", b"x", replace=False)
    item = ss.ItemIface(store, row_id)

    result = _raw(ss.ItemIface.delete)(item)

    assert result == ss.NULL_PATH
    with pytest.raises(KeyError):
        store.get(row_id)


# -- CollectionIface --------------------------------------------------------


def test_collection_iface_search_items_matches_superset(store):
    row_id = store.upsert(
        "label", {"service": "gh", "account": "me"}, "text/plain", b"x", replace=False
    )
    bus = FakeBus()
    collection = ss.CollectionIface(bus, store)

    paths = _raw(ss.CollectionIface.search_items)(collection, {"service": "gh"})

    assert paths == [ss.item_path(row_id)]
    assert ss.item_path(row_id) in bus.exported


def test_collection_iface_search_items_no_match_when_attribute_conflicts(store):
    store.upsert("label", {"service": "gh"}, "text/plain", b"x", replace=False)
    bus = FakeBus()
    collection = ss.CollectionIface(bus, store)

    paths = _raw(ss.CollectionIface.search_items)(
        collection, {"service": "gh", "account": "someone-else"}
    )

    assert paths == []


def test_collection_iface_export_item_is_idempotent(store):
    row_id = store.upsert("label", {"service": "gh"}, "text/plain", b"x", replace=False)
    bus = FakeBus()
    collection = ss.CollectionIface(bus, store)

    collection.export_item(row_id)
    collection.export_item(row_id)

    assert len(bus.exported) == 1


def test_collection_iface_create_item_new(store):
    bus = FakeBus()
    collection = ss.CollectionIface(bus, store)
    properties = {
        f"{ss.ITEM_IFACE}.Label": Variant("s", "mylabel"),
        f"{ss.ITEM_IFACE}.Attributes": Variant("a{ss}", {"service": "gh"}),
    }
    secret = ["/session/s1", b"", b"topsecret", "text/plain"]

    item_path, prompt = _raw(ss.CollectionIface.create_item)(collection, properties, secret, False)

    assert prompt == ss.NULL_PATH
    row_id = store.find_by_attributes({"service": "gh"})
    assert item_path == ss.item_path(row_id)
    _content_type, stored_secret = store.get(row_id)
    assert stored_secret == b"topsecret"
    assert item_path in bus.exported


def test_collection_iface_create_item_replace_updates_existing(store):
    existing_id = store.upsert("old", {"service": "gh"}, "text/plain", b"old-secret", replace=True)
    bus = FakeBus()
    collection = ss.CollectionIface(bus, store)
    properties = {
        f"{ss.ITEM_IFACE}.Label": Variant("s", "new"),
        f"{ss.ITEM_IFACE}.Attributes": Variant("a{ss}", {"service": "gh"}),
    }
    secret = ["/session/s1", b"", b"new-secret", "text/plain"]

    item_path, _prompt = _raw(ss.CollectionIface.create_item)(collection, properties, secret, True)

    assert item_path == ss.item_path(existing_id)
    _content_type, stored_secret = store.get(existing_id)
    assert stored_secret == b"new-secret"
    assert len(store.all_rows()) == 1
