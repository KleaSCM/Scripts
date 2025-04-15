#!/bin/bash
# @interactive
BASE_DIR="$HOME/Documents/Scripts"

# Define keyword-to-folder mappings
declare -A KEYWORDS=(
  [dev]="GoSetUp PythonSetUp CPP new_.* project .*Dev.*"
  [apps]="Spotify Obsidian Firefox LaunchT"
  [admin]="update clean session clipboard OSdiag OSUI SvTLayout WH TabM CleanT"
  [web]="flask html SimpHTML"
  [config]="Keybinds edit config Theme"
  [utils]="Utils Goddess TrsUI"
)

mkdir -p "$BASE_DIR/sorted"

# Create folders
for category in "${!KEYWORDS[@]}"; do
  mkdir -p "$BASE_DIR/sorted/$category"
done

# Move scripts into folders
for script in "$BASE_DIR"/*.sh; do
  filename=$(basename "$script")
  moved=false

  for category in "${!KEYWORDS[@]}"; do
    for keyword in ${KEYWORDS[$category]}; do
      if [[ "$filename" =~ $keyword ]]; then
        mv "$script" "$BASE_DIR/sorted/$category/"
        echo "Moved $filename → $category/"
        moved=true
        break 2
      fi
    done
  done

  if [ "$moved" = false ]; then
    mkdir -p "$BASE_DIR/sorted/uncategorized"
    mv "$script" "$BASE_DIR/sorted/uncategorized/"
    echo "Moved $filename → uncategorized/"
  fi
done
