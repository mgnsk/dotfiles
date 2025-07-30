#!/bin/env bash

set -euo pipefail

TMP_DIR="/tmp/screenshot.$$"
FILENAME="$TMP_DIR/screenshot.png"
mkdir -p "$TMP_DIR"

function cleanup {
	rm -rf "$TMP_DIR"
}

trap cleanup EXIT

INPUT_CHOICE=$(zenity --width=450 --height=400 --title "Screenshot" \
	--text "Take a screenshot of" \
	--list --radiolist \
	--column "Pick" \
	--column "Choice" \
	True "whole screen" \
	False "a part of the screen")

case $INPUT_CHOICE in
"whole screen")
	grim "$FILENAME"
	;;
"a part of the screen")
	slurp | grim -g - "$FILENAME"
	;;
"")
	exit
	;;
esac

OUTPUT_CHOICE=$(zenity --width=450 --height=400 --title "Select output" \
	--text "Take a screenshot of" \
	--list --radiolist \
	--column "Save file" \
	--column "Copy to clipboard" \
	True "save file" \
	False "copy to clipboard")

case $OUTPUT_CHOICE in
"save file")
	NAME="screenshot_$(date +"%FT%T").png"
	DEST=$(zenity --file-selection --title="Select a File" --filename="$NAME" --save 2>/dev/null)
	case $? in
	0)
		mv "$FILENAME" "$DEST"
		;;
	1)
		# No action.
		;;
	-1)
		echo "An unexpected error has occurred."
		;;
	esac
	;;
"copy to clipboard")
	wl-copy <"$FILENAME"
	;;
"")
	exit
	;;
esac
