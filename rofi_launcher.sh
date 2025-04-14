#!/bin/bash

# Script: rofi_launcher.sh
# Description: Enhanced script launcher with Rofi interface
# Author: KleaSCM
# Version: 2.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, rofi, find, notify-send, mpv

# Source common functions
source "$(dirname "$0")/sorted/lib/common.sh" || {
    echo "Error: Failed to load common functions"
    exit 1
}

# Configuration
SCRIPTS_DIR="$HOME/Documents/Scripts/sorted"
LOG_FILE="$SCRIPTS_DIR/logs/launcher.log"
DEBUG_LOG="/tmp/rofi_launcher_debug.log"
CONFIG_FILE="$SCRIPTS_DIR/config/launcher.conf"
SOUNDS_DIR="$SCRIPTS_DIR/sounds"

# Initialize logging
init_logging

# Clear debug log
echo "" > "$DEBUG_LOG"

# Load configuration if exists
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Function to get script description
get_script_description() {
    local script_path="$1"
    local description
    
    # Try to extract description from script header
    description=$(grep -m 1 "^# Description:" "$script_path" 2>/dev/null | sed 's/^# Description: //')
    
    if [[ -z "$description" ]]; then
        description="No description available"
    fi
    
    echo "$description"
}

# Function to validate script
validate_script() {
    local script_path="$1"
    
    echo "DEBUG: Validating script: $script_path" >> "$DEBUG_LOG"
    echo "DEBUG: Current directory: $(pwd)" >> "$DEBUG_LOG"
    echo "DEBUG: Script exists: $([[ -f "$script_path" ]] && echo "yes" || echo "no")" >> "$DEBUG_LOG"
    echo "DEBUG: Script permissions: $(ls -l "$script_path" 2>/dev/null)" >> "$DEBUG_LOG"
    
    if [[ ! -f "$script_path" ]]; then
        error "Script not found: $script_path"
        echo "ERROR: Script not found at path: $script_path" >> "$DEBUG_LOG"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        warn "Script is not executable, attempting to fix permissions"
        echo "WARN: Attempting to make script executable: $script_path" >> "$DEBUG_LOG"
        
        if ! chmod +x "$script_path"; then
            error "Failed to make script executable: $script_path"
            echo "ERROR: Failed to make script executable" >> "$DEBUG_LOG"
            echo "ERROR: Current permissions: $(ls -l "$script_path")" >> "$DEBUG_LOG"
            echo "ERROR: Current user: $(whoami)" >> "$DEBUG_LOG"
            return 1
        fi
        
        echo "SUCCESS: Made script executable" >> "$DEBUG_LOG"
    fi
    
    echo "SUCCESS: Script validated successfully" >> "$DEBUG_LOG"
    return 0
}

# Function to play sound effect
play_sound() {
    local sound="$1"
    if [[ -f "$SOUNDS_DIR/$sound" ]]; then
        mpv --no-video "$SOUNDS_DIR/$sound" &>/dev/null &
    fi
}

# Function to show notification
show_notification() {
    local title="$1"
    local message="$2"
    notify-send "$title" "$message"
}

# Function to display script selection
show_script_selection() {
    local category="$1"
    local scripts=()
    local descriptions=()
    
    echo "DEBUG: Showing script selection for category: $category" >> "$DEBUG_LOG"
    echo "DEBUG: Current directory: $(pwd)" >> "$DEBUG_LOG"
    
    # Add dashboard if in root category
    if [[ "$category" == "sorted" ]]; then
        local dashboard_path="$SCRIPTS_DIR/dashboard.sh"
        echo "DEBUG: Checking dashboard path: $dashboard_path" >> "$DEBUG_LOG"
        if [[ -f "$dashboard_path" ]]; then
            echo "DEBUG: Adding dashboard to options" >> "$DEBUG_LOG"
            scripts+=("dashboard")
            descriptions+=("Main dashboard interface")
        else
            echo "DEBUG: Dashboard not found at: $dashboard_path" >> "$DEBUG_LOG"
        fi
    fi
    
    # Find all scripts in category
    while IFS= read -r script; do
        local script_name="${script%.sh}"
        local script_path="$SCRIPTS_DIR/$category/$script"
        local description
        
        echo "DEBUG: Processing script: $script_path" >> "$DEBUG_LOG"
        
        if validate_script "$script_path"; then
            description=$(get_script_description "$script_path")
            scripts+=("$script_name")
            descriptions+=("$description")
            echo "DEBUG: Added script to options: $script_name" >> "$DEBUG_LOG"
        else
            echo "DEBUG: Failed to validate script: $script_path" >> "$DEBUG_LOG"
        fi
    done < <(find "$SCRIPTS_DIR/$category" -type f -name "*.sh" -printf "%f\n" | sort)
    
    # Create selection menu with descriptions
    local selection
    selection=$(printf "%s - %s\n" "${scripts[@]}" "${descriptions[@]}" | \
        rofi -dmenu -i -p "$category:" -format 's' -sep '-' -columns 1 -lines 10)
    
    [[ -z "$selection" ]] && return 1
    
    # Extract script name from selection
    echo "${selection%% - *}"
    return 0
}

# Main function
main() {
    log "Starting script launcher"
    echo "DEBUG: Starting main function" >> "$DEBUG_LOG"
    echo "DEBUG: SCRIPTS_DIR: $SCRIPTS_DIR" >> "$DEBUG_LOG"
    echo "DEBUG: Current directory: $(pwd)" >> "$DEBUG_LOG"
    
    # Play startup sound
    play_sound "startup.mp3"
    
    # Choose category
    local category
    category=$(find "$SCRIPTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | \
        rofi -dmenu -i -p "Category:")
    
    [[ -z "$category" ]] && {
        log "No category selected"
        exit 0
    }
    
    echo "DEBUG: Selected category: $category" >> "$DEBUG_LOG"
    
    # Choose script and sanitize whitespace
    local script
    script=$(show_script_selection "$category")
    script=$(echo "$script" | xargs)  # Remove leading/trailing whitespace
    
    [[ -z "$script" ]] && {
        log "No script selected"
        exit 0
    }
    
    echo "DEBUG: Selected script: $script" >> "$DEBUG_LOG"
    
    # Handle dashboard selection
    if [[ "$script" == "dashboard" ]]; then
        local script_path="$SCRIPTS_DIR/dashboard.sh"
    else
        local script_path="$SCRIPTS_DIR/$category/$script.sh"
    fi
    
    echo "DEBUG: Final script path: $script_path" >> "$DEBUG_LOG"
    
    # Validate and run script
    if validate_script "$script_path"; then
        log "Executing script: $script_path"
        show_notification "Script Launcher" "Starting $script..."
        play_sound "execute.mp3"
        
        start_timer
        "$script_path"
        local exit_code=$?
        
        log "Script execution completed in $(get_elapsed_time) with exit code: $exit_code"
        show_notification "Script Launcher" "Script completed with exit code: $exit_code"
        play_sound "complete.mp3"
        
        exit $exit_code
    else
        error "Failed to validate script: $script_path"
        show_notification "Script Launcher" "Failed to validate script: $script"
        play_sound "error.mp3"
        echo "ERROR: Final validation failed for: $script_path" >> "$DEBUG_LOG"
        echo "ERROR: Current directory: $(pwd)" >> "$DEBUG_LOG"
        echo "ERROR: Script exists: $([[ -f "$script_path" ]] && echo "yes" || echo "no")" >> "$DEBUG_LOG"
        echo "ERROR: Script permissions: $(ls -l "$script_path" 2>/dev/null)" >> "$DEBUG_LOG"
        exit 1
    fi
}

# Run main function
main "$@"
