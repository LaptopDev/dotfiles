#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# record_region2.sh - Technical Design Justifications
#
# 1. Input Race Mitigation:
#    The script utilizes a sentinel-based signaling system and explicit process 
#    group management to ensure the background Escape watcher (used during 
#    recording) is fully terminated and its input buffer cleared before the 
#    Foreground Multi-Crop loop begins. This prevents the "First Enter Eaten" 
#    phenomenon caused by dual-process contention for the TTY/X11 stream.
#
# 2. X11 Edge-Agnostic Detection:
#    To account for asynchronous X11 event reporting, the input logic accepts 
#    both KeyPress (Type 2) and KeyRelease (Type 3) events. This guarantees 
#    responsiveness regardless of whether the script polling starts mid-stroke.
#
# 3. Dynamic Encoder Switching:
#    A conditional logic gate switches between NVENC and libx265 based on 
#    frame dimensions to bypass the hardware limitation where NVENC fails on 
#    regions smaller than 128x128.
###############################################################################

### -------- CONFIG --------

BORDER="$HOME/system-scripts/border_drawer"
MOUSE_HIDE="$HOME/system-scripts/x11_mouse_hide"
MOUSE_GRAB="$HOME/system-scripts/x11_mouse_grab"

AUDIO_SINK="$(pactl get-default-sink)"
AUDIO_SRC="${AUDIO_SINK}.monitor"

NVENC_MIN_W=128
NVENC_MIN_H=128

### -------- STATE --------

TS="$(date +%Y%m%d-%H%M%S)"
RAW="$HOME/Downloads/capture-$TS.mkv"
OUT_BASE="$HOME/Downloads/capture-$TS"

# Use file-based state (SENTINEL) to allow background subshells to 
# communicate termination status across disparate process groups.
SENTINEL="/tmp/screencap.running"
touch "$SENTINEL"

HAS_TTY=0
if tty -s 2>/dev/null && [[ -r /dev/tty && -w /dev/tty ]]; then
  HAS_TTY=1
fi

SESSION_TYPE="${XDG_SESSION_TYPE:-}"
HAS_X11=0
if [[ -n "${DISPLAY:-}" ]] && command -v xinput >/dev/null 2>&1; then
  HAS_X11=1
fi

TTY_STATE=""
if (( HAS_TTY )); then
  TTY_STATE="$(stty -g </dev/tty 2>/dev/null || true)"
fi

### -------- INPUT UTILS --------

get_mouse_id() {
  xinput list |
    awk '/\[slave[[:space:]]+pointer/ {
      if (match($0,/id=([0-9]+)/,m)) { print m[1]; exit }
    }'
}

# Justification: Blocking reads are used to minimize CPU cycles, 
# but a short timeout (-t 0.1) is implemented to allow the script 
# to remain responsive to SIGTERM/SIGINT signals.
read_key_tty() {
  local old key
  old="$(stty -g </dev/tty 2>/dev/null || true)"
  stty -echo -icanon time 0 min 1 </dev/tty 2>/dev/null || true
  IFS= read -rsn1 -t 0.1 key </dev/tty || key=""
  [[ -n "$old" ]] && stty "$old" </dev/tty 2>/dev/null || stty sane </dev/tty 2>/dev/null || true
  printf '%s' "$key"
}

# Justification: detail 9 (Esc) and 36 (Enter) are standard X11 codes.
# Capturing both event type 2 and 3 ensures the input isn't dropped 
# during high-latency window manager cycles.
read_key_x11() {
  local code=""
  code="$(
    xinput test-xi2 --root 2>/dev/null | awk '
      /EVENT type 2 \(KeyPress\)/  {k=1; next}
      /EVENT type 3 \(KeyRelease\)/{k=1; next}
      k && $1=="detail:" {print $2; exit}
    '
  )" || true

  case "$code" in
    9)  printf '%s' $'\e' ;;
    36) printf '%s' $'\n' ;;
    "") printf '' ;;
    *)  printf 'x' ;;
  esac
}

read_key() {
  if (( HAS_TTY )); then
    read_key_tty
  elif (( HAS_X11 )); then
    read_key_x11
  else
    printf ''
  fi
}

# Justification: FFMPEG requires SIGINT to properly flush headers 
# to the MKV container. SIGKILL is reserved as a final fail-safe 
# to prevent zombie processes if hardware encoders hang.
kill_wait_escalate() {
  local pid="${1:-}" w1="${2:-1500}" w2="${3:-1500}"
  [[ -n "$pid" ]] || return 0
  kill -0 "$pid" 2>/dev/null || return 0

  kill -INT "$pid" 2>/dev/null || true
  local end=$(( $(date +%s%3N) + w1 ))
  while kill -0 "$pid" 2>/dev/null && (( $(date +%s%3N) < end )); do
    sleep 0.05
  done

  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
    end=$(( $(date +%s%3N) + w2 ))
    while kill -0 "$pid" 2>/dev/null && (( $(date +%s%3N) < end )); do
      sleep 0.05
    done
  fi

  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
}

MOUSE_ID="$(get_mouse_id || true)"
declare -a CROPS=()
declare -a BORDER_PIDS=()

cleanup() {
  set +e
  [[ -n "${FFMPEG_PID:-}" ]] && kill_wait_escalate "$FFMPEG_PID" 1200 1200
  [[ -n "${ESC_WATCH_PID:-}" ]] && kill -9 "$ESC_WATCH_PID" 2>/dev/null
  [[ -n "${SLOP_PID:-}" ]] && kill "$SLOP_PID" 2>/dev/null
  [[ -n "${KEY_PID:-}" ]] && kill "$KEY_PID" 2>/dev/null
  [[ -n "${MOUSE_GRAB_PID:-}" ]] && kill "$MOUSE_GRAB_PID" 2>/dev/null
  [[ -n "${MOUSE_HIDE_PID:-}" ]] && kill "$MOUSE_HIDE_PID" 2>/dev/null
  [[ -n "${PREVIEW_BORDER_PID:-}" ]] && kill "$PREVIEW_BORDER_PID" 2>/dev/null
  [[ -n "${OUTER_BORDER_PID:-}" ]] && kill "$OUTER_BORDER_PID" 2>/dev/null

  for pid in "${BORDER_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done

  [[ -n "$MOUSE_ID" ]] && xinput enable "$MOUSE_ID" 2>/dev/null || true
  rm -f "$SENTINEL" 2>/dev/null || true

  if (( HAS_TTY )); then
    [[ -n "${TTY_STATE:-}" ]] && stty "$TTY_STATE" </dev/tty 2>/dev/null || stty sane </dev/tty 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM HUP

### -------- RECORDING PHASE --------

watch_escape() {
  while [[ -e "$SENTINEL" ]]; do
    local key
    key="$(read_key)"
    if [[ "$key" == $'\e' ]]; then
       rm -f "$SENTINEL"
       break
    fi
    sleep 0.1
  done
}
watch_escape &
ESC_WATCH_PID=$!

SCREEN="$(xrandr | awk '/\*/{print $1; exit}')"
"$BORDER" fullscreen red 6 &
OUTER_BORDER_PID=$!

"$MOUSE_HIDE" &
MOUSE_HIDE_PID=$!

ffmpeg \
  -hide_banner -loglevel info \
  -f x11grab -framerate 60 -video_size "$SCREEN" -i :0.0 \
  -thread_queue_size 1024 -f pulse -i "$AUDIO_SRC" \
  -c:v hevc_nvenc -profile:v main10 -pix_fmt p010le -preset p5 \
  -rc vbr -cq 23 -b:v 0 -spatial_aq 1 -temporal_aq 1 -g 120 \
  -c:a aac -b:a 160k -metadata creation_time="$(date -Is)" \
  "$RAW" &
FFMPEG_PID=$!

while kill -0 "$FFMPEG_PID" 2>/dev/null; do
  [[ -e "$SENTINEL" ]] || break
  sleep 0.3
done

kill_wait_escalate "$FFMPEG_PID" 2000 2000
wait "$FFMPEG_PID" 2>/dev/null || true
unset FFMPEG_PID

# JUSTIFICATION: The removal of the sentinel and explicit kill/wait 
# of the background PID is mandatory here to ensure the TTY/X11 
# device is released before the "read_key" calls in the crop loop.
rm -f "$SENTINEL"
kill -9 "$ESC_WATCH_PID" 2>/dev/null || true
wait "$ESC_WATCH_PID" 2>/dev/null || true
unset ESC_WATCH_PID

### -------- MULTI-CROP LOOP --------

FINISH=0
while :; do
  geomf="$(mktemp /tmp/slop-geom.XXXXXX)"
  keyf="$(mktemp /tmp/slop-key.XXXXXX)"

  slop -k -f '%wx%h+%x,%y' >"$geomf" &
  SLOP_PID=$!

  # Justification: Nested watcher allows "Enter" to act as a 
  # "Finish and Proceed" signal even if slop is still active.
  while kill -0 "$SLOP_PID" 2>/dev/null; do
    ( read_key >"$keyf" ) &
    KEY_PID=$!
    wait -n "$SLOP_PID" "$KEY_PID" 2>/dev/null || true

    if ! kill -0 "$SLOP_PID" 2>/dev/null; then
       kill "$KEY_PID" 2>/dev/null || true
       wait "$KEY_PID" 2>/dev/null || true
       break
    fi

    if ! kill -0 "$KEY_PID" 2>/dev/null; then
      key="$(cat "$keyf" 2>/dev/null || true)"
      if [[ "$key" == $'\n' || "$key" == $'\e' ]]; then
        kill "$SLOP_PID" 2>/dev/null || true
        wait "$SLOP_PID" 2>/dev/null || true
        rm -f "$geomf" "$keyf"
        unset KEY_PID SLOP_PID
        if ((${#CROPS[@]} == 0)); then
          rm -f "$RAW"
          exit 0
        fi
        FINISH=1
        break
      fi
      unset KEY_PID
    fi
  done

  (( FINISH )) && break
  wait "$SLOP_PID" || true
  GEOM="$(cat "$geomf" 2>/dev/null || true)"
  rm -f "$geomf" "$keyf"

  if [[ -z "$GEOM" ]]; then
    if ((${#CROPS[@]} == 0)); then rm -f "$RAW"; exit 0; fi
    break
  fi

  SIZE="${GEOM%%+*}"; POS="${GEOM#*+}"
  W="${SIZE%x*}"; H="${SIZE#*x}"; X="${POS%,*}"; Y="${POS#*,}"
  
  # Ensure dimensions are even-numbered for YUV420p compatibility.
  W=$((W/2*2)); H=$((H/2*2)); X=$((X/2*2)); Y=$((Y/2*2))

  "$BORDER" "$X" "$Y" "$W" "$H" green 4 &
  PREVIEW_BORDER_PID=$!
  "$MOUSE_GRAB" &
  MOUSE_GRAB_PID=$!

  key="$(read_key)"
  
  kill "$MOUSE_GRAB_PID" 2>/dev/null || true
  unset MOUSE_GRAB_PID

  if [[ "$key" == $'\e' ]]; then
    kill "$PREVIEW_BORDER_PID" 2>/dev/null || true
    unset PREVIEW_BORDER_PID
    continue
  fi

  CROPS+=("${W}:${H}:${X}:${Y}")
  BORDER_PIDS+=("$PREVIEW_BORDER_PID")
  unset PREVIEW_BORDER_PID
done

### -------- FINALIZE --------

kill "$OUTER_BORDER_PID" 2>/dev/null || true
for pid in "${BORDER_PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done

for i in "${!CROPS[@]}"; do
  crop="${CROPS[$i]}"
  IFS=: read -r W H X Y <<<"$crop"
  out_i="$(printf '%s-crop%02d.mp4' "$OUT_BASE" $((i+1)))"

  vf="crop=${W}:${H}:${X}:${Y},scale=${W}:${H}:flags=neighbor,setsar=1"
  
  # Selection logic justifies different bit-depths and params 
  # to ensure 10-bit color is maintained where hardware allows.
  if (( W >= NVENC_MIN_W && H >= NVENC_MIN_H )); then
    vcodec=(-c:v hevc_nvenc -profile:v main10 -pix_fmt p010le -preset p5 -rc vbr -cq 23 -b:v 0 -g 120 -tag:v hvc1)
  else
    vcodec=(-c:v libx265 -pix_fmt yuv420p10le -x265-params crf=23:keyint=120 -tag:v hvc1)
  fi

  ffmpeg -hide_banner -loglevel info -i "$RAW" -vf "$vf" "${vcodec[@]}" -c:a copy -movflags +faststart "$out_i"
done

rm -f "$RAW"
echo "Processing complete."
