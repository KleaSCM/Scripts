#!/bin/bash

# Script: common.sh
# Description: Common functions and utilities for all scripts
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

# Common functions and utilities for all scripts

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2
}

# Configuration functions
load_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        warn "Configuration file not found: $config_file"
        return 1
    fi
}

# Dependency checking
check_dependencies() {
    local deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Version checking
check_version() {
    local cmd="$1"
    local min_version="$2"
    local version
    
    version=$("$cmd" --version 2>&1 | head -n1 | grep -o '[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?')
    if [[ "$(printf '%s\n' "$min_version" "$version" | sort -V | head -n1)" != "$min_version" ]]; then
        error "$cmd version $version is less than required version $min_version"
        return 1
    fi
}

# File operations
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")/backup}"
    local timestamp
    
    timestamp=$(date '+%Y%m%d_%H%M%S')
    mkdir -p "$backup_dir"
    cp "$file" "$backup_dir/$(basename "$file").$timestamp"
}

# Security functions
check_permissions() {
    local file="$1"
    local required_perms="$2"
    
    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        return 1
    fi
    
    local current_perms=$(stat -c "%a" "$file")
    if [[ "$current_perms" != "$required_perms" ]]; then
        error "Incorrect permissions for $file. Expected $required_perms, got $current_perms"
        return 1
    fi
}

# Utility functions
is_root() {
    [[ $EUID -eq 0 ]]
}

require_root() {
    if ! is_root; then
        error "This script must be run as root"
        exit 1
    fi
}

# Time tracking
start_timer() {
    SECONDS=0
}

get_elapsed_time() {
    echo "$SECONDS seconds"
}

# Export functions
export -f log error warn load_config check_dependencies check_version
export -f backup_file check_permissions is_root require_root
export -f start_timer get_elapsed_time 