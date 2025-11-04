#!/usr/bin/env bash
# X11-only, PNG-only: OCR clipboard image → replace clipboard with quoted text
set -euo pipefail

tmp="$(mktemp /tmp/ocrclip.XXXXXX.png)"

# Read PNG from X11 clipboard
xclip -selection clipboard -t image/png -o >"$tmp" 2>/dev/null || { echo "No PNG image in clipboard"; exit 2; }

# OCR → quote → clipboard
tesseract "$tmp" - -l "${LANGS:-eng}" --psm "${PSM:-6}" 2>/dev/null \
  | sed '1s/^/"/; $s/$/"/' \
  | xsel --clipboard --input

rm -f "$tmp"
