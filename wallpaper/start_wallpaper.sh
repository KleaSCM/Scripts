
#!/bin/bash

WALLPAPER="$1"

# Check if path exists
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  echo "Usage: $0 /path/to/image.jpg|.png|.webm|.mp4"
  exit 1
fi

# Kill existing xwinwraps
pkill -f xwinwrap

# Start xwinwrap with feh persistently
xwinwrap -fs -ni -b -nf -un -o 1.0 -ov -- \
  feh --zoom fill --bg-scale "$WALLPAPER" &


