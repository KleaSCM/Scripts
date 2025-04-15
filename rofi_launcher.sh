#!/bin/bash

# Script: rofi_launcher.sh
# Description: Rofi-based script launcher with performance monitoring and wallpaper selection
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, rofi, notify-send, sxiv, feh (optional)

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sorted/lib/common.sh" || {
    echo "Error: Failed to load common functions"
    exit 1
}

# Initialize logging
init_logging

# Configuration
CONFIG_DIR="$SCRIPT_DIR/sorted/config"
CONFIG_FILE="$CONFIG_DIR/rofi_launcher.conf"
LOG_FILE="$SCRIPT_DIR/sorted/logs/launcher_history.log"
WALLPAPER_DIR="/home/klea/Pictures/wallpaper"
PREVIEW_SIZE="200x200"  # Size for preview images

# Terminal emulators in order of preference
TERMINALS=(
    "kitty --hold"
    "alacritty -e"
    "wezterm start"
    "foot"
    "konsole --noclose -e"
    "xterm -e"
)

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to set wallpaper using qdbus
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
    notify-send "Wallpaper Set" "Set to $(basename "$file")"
}

# Function to show categories
show_categories() {
    local mode="$1"
    local wall_dir="$WALLPAPER_DIR/$mode"
    
    # Get list of categories (subdirectories)
    local categories=$(find "$wall_dir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
        echo "$(basename "$dir") - $dir"
    done)
    
    # Add "All" option
    echo "All - $wall_dir"
    echo "$categories"
}

# Function to show wallpaper selection with preview
show_wallpaper_selection() {
    local mode="$1"
    local category="$2"
    local wall_dir="$WALLPAPER_DIR/$mode"
    
    # If category is "All", use the main directory
    if [ "$category" = "All" ]; then
        wall_dir="$WALLPAPER_DIR/$mode"
    else
        wall_dir="$WALLPAPER_DIR/$mode/$category"
    fi
    
    # Get list of wallpapers
    local wallpapers=$(find "$wall_dir" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)
    
    # Format for rofi with preview
    local selection=$(echo "$wallpapers" | while read -r wall; do
        # Generate preview if it doesn't exist
        local preview_dir="$HOME/.cache/wallpaper_previews"
        local preview_file="$preview_dir/$(basename "$wall").preview.jpg"
        mkdir -p "$preview_dir"
        
        if [ ! -f "$preview_file" ]; then
            convert "$wall" -resize "$PREVIEW_SIZE" "$preview_file" 2>/dev/null || \
            magick "$wall" -resize "$PREVIEW_SIZE" "$preview_file" 2>/dev/null
        fi
        
        # Show preview in rofi if available
        if [ -f "$preview_file" ]; then
            echo -e "$(basename "$wall")\x00icon\x1f$preview_file"
        else
            echo "$(basename "$wall")"
        fi
    done | rofi -dmenu -p "Select wallpaper:" -i -theme-str 'entry { placeholder: "Search..."; }' -show-icons)
    
    # Extract the full path
    if [ -n "$selection" ]; then
        # Remove the icon part if present
        selection=$(echo "$selection" | sed 's/\x00icon.*//')
        find "$wall_dir" -name "$selection" -type f | head -n1
    fi
}

# Function to handle wallpaper mode selection
handle_wallpaper_mode() {
    local mode=$(printf "Static\nDynamic" | rofi -dmenu -p "Wallpaper Mode:" -i)
    
    case "$mode" in
        "Static")
            # Show categories
            local category=$(show_categories "static" | rofi -dmenu -p "Select Category:" -i)
            if [ -z "$category" ]; then
                return 1
            fi
            
            # Extract category name
            category=$(echo "$category" | awk -F ' - ' '{print $1}')
            
            # Show wallpapers in selected category
            local selected_wall=$(show_wallpaper_selection "static" "$category")
            if [ -n "$selected_wall" ]; then
                set_wallpaper "$selected_wall"
            fi
            ;;
        "Dynamic")
            # For dynamic, we'll just show a notification for now
            notify-send "Dynamic Wallpaper" "Dynamic wallpaper mode selected"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to display script selection menu
show_script_selection() {
    # Find all .sh files in the sorted directory and its subdirectories
    local scripts=$(find "$SCRIPT_DIR/sorted" -type f -name "*.sh" | sort)
    
    # Format for rofi with category and full path preserved
    local selection=$(echo "$scripts" | while read -r script; do
        category=$(basename "$(dirname "$script")")
        echo "[$category] $(basename "$script") - $script"
    done | rofi -dmenu -p "Select script:" -i)
    
    # Return the full path of the selected script
    if [ -n "$selection" ]; then
        echo "$selection" | awk -F ' - ' '{print $2}'
    fi
}

# Function to start performance timer
start_timer() {
    start_time=$(date +%s.%N)
}

# Function to stop timer and calculate duration
stop_timer() {
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "$duration"
}

# Function to monitor system resources
monitor_resources() {
    local pid=$1
    local max_cpu=0
    local max_mem=0
    
    # Wait a short time to ensure the process is running
    sleep 0.05
    
    while kill -0 $pid 2>/dev/null; do
        local cpu=$(ps -p $pid -o %cpu | tail -n1)
        local mem=$(ps -p $pid -o %mem | tail -n1)
        
        # Update max values if current values are higher
        if (( $(echo "$cpu > $max_cpu" | bc -l) )); then
            max_cpu=$cpu
        fi
        if (( $(echo "$mem > $max_mem" | bc -l) )); then
            max_mem=$mem
        fi
        
        sleep 0.1
    done
    
    echo "$max_cpu $max_mem"
}

# Function to launch script in terminal
launch_in_terminal() {
    local script_path="$1"
    
    for term in "${TERMINALS[@]}"; do
        local term_cmd=$(echo "$term" | cut -d' ' -f1)
        if command -v "$term_cmd" &>/dev/null; then
            $term bash "$script_path" &
            return $?
        fi
    done
    
    notify-send "Script Launcher" "No terminal emulator found for interactive script."
    return 1
}

# Main function
main() {
    # Show initial mode selection
    local mode=$(printf "Scripts\nWallpapers" | rofi -dmenu -p "Select Mode:" -i)
    
    case "$mode" in
        "Scripts")
            # Show script selection menu
            local script_path=$(show_script_selection)
            
            # Exit if no script was selected
            if [ -z "$script_path" ]; then
                echo "No script selected"
                exit 0
            fi
            
            # Validate script path is within sorted directory
            if [[ "$script_path" != "$SCRIPT_DIR/sorted/"* ]]; then
                notify-send "Invalid Selection" "Selected script is not within $SCRIPT_DIR/sorted"
                exit 1
            fi
            
            # Make script executable if it isn't already
            [[ -x "$script_path" ]] || chmod +x "$script_path"
            
            # Check if script is interactive
            if grep -q "^# @interactive" "$script_path"; then
                # Launch in terminal
                if launch_in_terminal "$script_path"; then
                    # Skip monitoring and logging for terminal-based interactive scripts
                    echo "$(date '+%F %T') | $script_path | Launched in terminal." >> "$LOG_FILE"
                    notify-send "Script Launched in Terminal" "$script_path"
                    exit 0
                else
                    notify-send "Script Launcher Error" "Failed to launch in terminal."
                    exit 1
                fi
            fi
            
            # Start the timer
            start_timer
            
            # Create temporary file for resource monitoring
            local resource_tmp=$(mktemp)
            
            # Run non-interactive script silently
            bash "$script_path" &
            local script_pid=$!
            
            # Monitor resources in background and save to temp file
            monitor_resources $script_pid > "$resource_tmp" &
            local monitor_pid=$!
            
            # Wait for the script to finish and get its exit code
            wait $script_pid
            local exit_code=$?
            
            # Wait for monitor to finish and get the results
            wait $monitor_pid
            read max_cpu max_mem < "$resource_tmp"
            rm "$resource_tmp"
            
            # Stop the timer and get the duration
            local duration=$(stop_timer)
            
            # Log the execution
            echo "$(date '+%F %T') | $script_path | Duration: ${duration}s | CPU: ${max_cpu}% | MEM: ${max_mem}%" >> "$LOG_FILE"
            
            # Display performance summary
            echo -e "${BLUE}Performance Summary:${NC}"
            echo -e "Duration: ${YELLOW}${duration}s${NC}"
            echo -e "Max CPU Usage: ${YELLOW}${max_cpu}%${NC}"
            echo -e "Max Memory Usage: ${YELLOW}${max_mem}%${NC}"
            
            # Send desktop notification
            if [ $exit_code -eq 0 ]; then
                notify-send "Script Completed" "Duration: ${duration}s\nMax CPU: ${max_cpu}%\nMax Memory: ${max_mem}%"
            else
                notify-send "Script Failed" "Exit code: $exit_code\nDuration: ${duration}s"
            fi
            ;;
            
        "Wallpapers")
            handle_wallpaper_mode
            ;;
            
        *)
            exit 0
            ;;
    esac
}

# Run the main function
main
