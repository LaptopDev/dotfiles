#!/bin/bash
set -euo pipefail

TMP_WAV="$(mktemp /tmp/piper-tts-XXXXXX.wav)"
MPV_SOCK="/tmp/mpvsock"

cleanup() {
    [[ -n "${MPV_PID:-}" ]] && kill "$MPV_PID" 2>/dev/null || true
    rm -f "$TMP_WAV" "$MPV_SOCK"
}
trap cleanup EXIT

# --- TTS pipeline: clipboard -> piper -> sox -> wav file ---
xsel -bo | /home/user/.local/bin/piper \
    --model /home/user/Downloads/en_US-lessac-medium.onnx \
    --config /home/user/Downloads/en_US-lessac-medium.onnx.json \
    --output_raw | \
sox -t raw -r 22050 -e signed -b 16 -c 1 - \
    "$TMP_WAV" \
    gain -3 pitch -300

# --- launch mpv ---
mpv --input-ipc-server="$MPV_SOCK" \
    --script=~/.config/mpv/scripts/overlay-status.lua \
    --script=~/.config/mpv/scripts/hardboundary.lua \
    --script=~/.config/mpv/scripts/media-control.lua \
    --keep-open=yes \
    "$TMP_WAV" &

MPV_PID=$!

# --- persistent blocking notification ---
dunstify -u low -t 0 -b "TTS playback" "Scroll to seek with media keys"

# --- cleanup when dismissed ---
kill "$MPV_PID"
wait "$MPV_PID" 2>/dev/null || true
