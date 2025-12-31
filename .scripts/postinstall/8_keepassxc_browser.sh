#!/bin/env bash

user=$(id -un)

# Find keepassxc extension ID.
extID=$(cat "$XDG_RUNTIME_DIR/psd/$user-brave/Default/Preferences" |
	gojq -r '.extensions.settings | to_entries[] | select(.value.path | endswith("/.browser-extensions/keepassxc-browser/keepassxc-browser")) | .key')

target="$XDG_RUNTIME_DIR/psd/$user-brave/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json"

# If not exists in allowed_origins, then add.
if ! gojq -e --arg extID "$extID" '.allowed_origins[] | select(contains($extID))' "$target" >/dev/null; then
	tmp=$(mktemp)
	gojq --arg extID "$extID" '.allowed_origins += ["chrome-extension://" + $extID + "/"]' "$target" >"$tmp"
	mv "$tmp" "$target"
fi
