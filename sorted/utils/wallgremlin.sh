#!/bin/bash
# @interactive
# Script: wallgremlin.sh
# Description: Wallpaper management and rotation tool
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, rofi, qdbus, notify-send

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" || {
    echo "Error: Failed to load common functions"
    exit 1
}

# Initialize logging
init_logging

# Configuration
CONFIG_DIR="$SCRIPT_DIR/../config"
CONFIG_FILE="$CONFIG_DIR/wallgremlin.conf"
WALL_DIR="/home/klea/Pictures/wallpapers"
LOG_FILE="$HOME/.cache/wallgremlin.log"

# Make sure wallpaper directory exists
mkdir -p "$WALL_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Load configuration
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    
    # Default settings
    ROTATION_INTERVAL=${ROTATION_INTERVAL:-300}  # 5 minutes default
    NOTIFICATIONS=${NOTIFICATIONS:-true}
}

# ASCII header for max cuteness
show_banner() {
    echo "┌────────────────────────────┐"
    echo "│ 🧃  WallGremlin v1.0       │"
    echo "│ 🐾  aesthetic injector      │"
    echo "└────────────────────────────┘"
}

# Show categories
choose_category() {
    find "$WALL_DIR" -mindepth 1 -maxdepth 1 -type d | sed "s|$WALL_DIR/||" | rofi -dmenu -p "🧸 Category:"
}

# Choose mode
choose_mode() {
    printf "Static Wallpaper\nRotating Slideshow\n" | rofi -dmenu -p "✨ Mode:"
}

# Choose a file from selected category
choose_file() {
    local category="$1"
    find "$WALL_DIR/$category" -type f \( -iname "*.jpg" -o -iname "*.png" \) | rofi -dmenu -p "🖼 Select wallpaper:"
}

# Set the wallpaper using qdbus
set_wallpaper() {
    local file="$1"
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (i=0;i<allDesktops.length;i++) {
      d = allDesktops[i];
      d.wallpaperPlugin = 'org.kde.image';
      d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
      d.writeConfig('Image', 'file://$file');
    }"
    echo "$(date): Wallpaper set to $file" >> "$LOG_FILE"
    [[ "$NOTIFICATIONS" == "true" ]] && notify-send "WallGremlin" "🌸 Wallpaper set to $(basename "$file")"
}

# Rotating slideshow logic
start_rotation() {
    local category="$1"
    local interval="$2"

    # Kill any existing gremlin
    if [[ -f "$HOME/.cache/wallgremlin_pid" ]]; then
        kill "$(cat "$HOME/.cache/wallgremlin_pid")" &>/dev/null
        rm "$HOME/.cache/wallgremlin_pid"
    fi

    (
        while true; do
            find "$WALL_DIR/$category" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort -R | while read -r wall; do
                set_wallpaper "$wall"
                sleep "$interval"
            done
        done
    ) &
    echo $! > "$HOME/.cache/wallgremlin_pid"
    [[ "$NOTIFICATIONS" == "true" ]] && notify-send "WallGremlin" "✨ Rotation started: $category every $interval seconds"
}

# Main flow
main() {
    load_config
    show_banner
    mode=$(choose_mode) || exit 0
    category=$(choose_category) || exit 0

    case "$mode" in
        "Static Wallpaper")
            file=$(choose_file "$category") || exit 0
            set_wallpaper "$file"
            ;;
        "Rotating Slideshow")
            interval=$(rofi -dmenu -p "🕒 Interval (sec):" -lines 1 -width 20 -theme-str 'entry { placeholder: "300"; }')
            [[ -z "$interval" ]] && interval="$ROTATION_INTERVAL"
            start_rotation "$category" "$interval"
            ;;
        *)
            [[ "$NOTIFICATIONS" == "true" ]] && notify-send "WallGremlin" "❌ Invalid selection"
            ;;
    esac
}

main
