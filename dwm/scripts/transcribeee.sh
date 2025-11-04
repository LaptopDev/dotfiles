#!/usr/bin/env bash
#
# To do: MUST USE SILERO with long input 
# To do: `retranscribe` alias can be extended to call mpv for given file for manual segment selection prior to batching those segments and creating the file.txt
# To do: for silero, add VAD separation for “both” mode.
# To do: prepend playback metadata (URL, timestamp, handle) when input is loopback.
# To do: unify notification icons and ensure accurate source labels.
# To do: make this callable as a CLI utility for pre-recorded .wav files. (base it off of retranscribe alias)

set -euo pipefail

# CONFIG
DIR="${HOME}/.transcription"
mkdir -p "$DIR"
WHISPER_BIN="/home/user/source/git/whisper_gpu.cpp/bin/whisper-cli"
WHISPER_MODEL="/home/user/source/git/whisper_gpu.cpp/models/ggml-large-v3.bin"

# deps
for cmd in ffmpeg ffprobe pactl wpctl notify-send xsel; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 127; }
done
[ -x "$WHISPER_BIN" ] || { echo "Missing whisper binary: $WHISPER_BIN" >&2; exit 127; }
[ -f "$WHISPER_MODEL" ] || { echo "Missing model file: $WHISPER_MODEL" >&2; exit 127; }

notify() {
  notify-send "Recorder" "$*" 2>/dev/null || echo "[Recorder] $*"
}

transcribe() {
  local file="$1"
  [[ -f "$file" ]] || { notify "No file to transcribe: $file"; return; }

  notify "Transcribing $(basename "$file")"
  local start_time end_time duration out txt
  start_time=$(date +%s)

  # whisper.cpp GPU transcription
  out=$("$WHISPER_BIN" \
    -m "$WHISPER_MODEL" \
    -f "$file" \
    -nt \
    --word-thold 0.005 \
    -sow \
    --entropy-thold 3.5 \
    | perl -CSAD -pe 's/^\s+|\s+$//g'
  )

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  txt="${file%.wav}.txt"
  printf '%s\n' "$out" > "$txt"

  # Copy to clipboard via xsel (fallback xclip)
  if command -v xsel >/dev/null 2>&1; then
    printf '%s' "$out" | xsel --clipboard --input
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$out" | xclip -selection clipboard
  fi

  notify "Saved transcription: $(basename "$txt") (${duration}s)"
}

# --- MODE SELECTION ---

mode="${1:-dt}"
case "$mode" in
  dt) ;;
  me) ;;
  both) ;;
  *) echo "Usage: $0 [dt|me|both]" >&2; exit 2;;
esac

MIC_SRC="$(pactl get-default-source)"

# Fallback logic: wpctl if available, else pactl
if command -v wpctl >/dev/null 2>&1; then
  SINK="$(wpctl status | awk '/Default Configured Devices:/{f=1;next} f&&/Audio\/Sink/{print $NF; exit}')"
else
  SINK="$(pactl get-default-sink)"
fi
DESK_MON="${SINK:+$SINK.monitor}"

ts=$(date '+%F_%H-%M-%S')
wav_dt="${DIR}/${ts}-dt.wav"
wav_me="${DIR}/${ts}-me.wav"

echo "Mode: $mode — recording; PID will follow"
case "$mode" in
  dt)
    [[ -n "$DESK_MON" ]] || { notify "No desktop sink"; exit 1; }
    notify "Recording desktop audio" "with $DESK_MON"
    ffmpeg -hide_banner -loglevel error -f pulse -i "$DESK_MON" \
      -ar 16000 -ac 1 -c:a pcm_s16le "$wav_dt" &
    pid=$!
    ;;
  me)
    [[ -n "$MIC_SRC" ]] || { notify "No mic source"; exit 1; }
    notify "Recording microphone" "with $MIC_SRC"
    ffmpeg -hide_banner -loglevel error -f pulse -i "$MIC_SRC" \
      -ar 16000 -ac 1 -c:a pcm_s16le "$wav_me" &
    pid=$!
    ;;
  both)
    [[ -n "$DESK_MON" && -n "$MIC_SRC" ]] || { notify "Missing devices"; exit 1; }
    notify "Recording desktop and microphone" "with $DESK_MON and $MIC_SRC"
    ffmpeg -hide_banner -loglevel error \
      -f pulse -i "$DESK_MON" -f pulse -i "$MIC_SRC" \
      -map 0:a -ar 16000 -ac 1 -c:a pcm_s16le "$wav_dt" \
      -map 1:a -ar 16000 -ac 1 -c:a pcm_s16le "$wav_me" &
    pid=$!
    ;;
esac

echo "$pid"
wait "$pid" || true

# --- TRANSCRIBE ---
case "$mode" in
  dt) [[ -s "$wav_dt" ]] && transcribe "$wav_dt" || notify "No desktop recording";;
  me) [[ -s "$wav_me" ]] && transcribe "$wav_me" || notify "No mic recording";;
  both)
    [[ -s "$wav_dt" ]] && transcribe "$wav_dt"
    [[ -s "$wav_me" ]] && transcribe "$wav_me"
    ;;
esac

exit 0
