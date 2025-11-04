#!/usr/bin/env bash
# Toggle GNOME color-scheme between 'prefer-dark' and 'default' using gsettings

current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)

if printf '%s' "$current" | grep -q "prefer-dark"; then
  gsettings set org.gnome.desktop.interface color-scheme 'default'
  echo "Switched to light"
else
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  echo "Switched to dark"
fi
