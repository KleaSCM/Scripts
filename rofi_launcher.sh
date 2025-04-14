#!/bin/bash

# Script: rofi_launcher.sh
# Description: Enhanced script launcher with Rofi interface
# Author: System
# Version: 2.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, rofi, find

# Source common functions
source "$(dirname "$0")/sorted/lib/common.sh" || {
    echo "Error: Failed to load common functions"
    exit 1
}

# Configuration
SCRIPTS_DIR="$HOME/Documents/Scripts/sorted"
LOG_FILE="$SCRIPTS_DIR/logs/launcher.log"
CONFIG_FILE="$SCRIPTS_DIR/config/launcher.conf"

# Initialize logging
init_logging

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
    
    if [[ ! -f "$script_path" ]]; then
        error "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        warn "Script is not executable, attempting to fix permissions"
        chmod +x "$script_path" || {
            error "Failed to make script executable"
            return 1
        }
    fi
    
    return 0
}

# Function to display script selection
show_script_selection() {
    local category="$1"
    local scripts=()
    local descriptions=()
    
    # Find all scripts in category
    while IFS= read -r script; do
        local script_name="${script%.sh}"
        local script_path="$SCRIPTS_DIR/$category/$script"
        local description
        
        if validate_script "$script_path"; then
            description=$(get_script_description "$script_path")
            scripts+=("$script_name")
            descriptions+=("$description")
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
    
    # Choose category
    local category
    category=$(find "$SCRIPTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | \
        rofi -dmenu -i -p "Category:")
    
    [[ -z "$category" ]] && {
        log "No category selected"
        exit 0
    }
    
    # Choose script
    local script
    script=$(show_script_selection "$category")
    
    [[ -z "$script" ]] && {
        log "No script selected"
        exit 0
    }
    
    local script_path="$SCRIPTS_DIR/$category/$script.sh"
    
    # Validate and run script
    if validate_script "$script_path"; then
        log "Executing script: $script_path"
        start_timer
        "$script_path"
        local exit_code=$?
        log "Script execution completed in $(get_elapsed_time) with exit code: $exit_code"
        exit $exit_code
    else
        error "Failed to validate script: $script_path"
        exit 1
    fi
}

# Run main function
main "$@"
