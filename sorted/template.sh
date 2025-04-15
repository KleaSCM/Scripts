#!/bin/bash

# Script: template.sh
# Description: Template script with standardized structure
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

# Configuration
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/${SCRIPT_NAME%.sh}.log"
CONFIG_FILE="${SCRIPT_DIR}/config/${SCRIPT_NAME%.sh}.conf"

# Source common functions and configuration
source "${SCRIPT_DIR}/../lib/common.sh" 2>/dev/null || {
    echo "Error: common.sh not found"
    exit 1
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "Script ended with exit code: $exit_code"
    exec 1>&3 2>&4
    exit $exit_code
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Version: 1.0.0"
                exit 0
                ;;
            *)
                log "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # Your script logic here
    log "Starting script execution"
    
    # Example command with error handling
    if ! some_command; then
        error "Command failed"
        exit 1
    fi

    log "Script completed successfully"
}

# Show help
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -h, --help      Show this help message
    -v, --version   Show version information

Description:
    This is a template script demonstrating proper structure and error handling.
EOF
}

# Initialize
init_logging
trap cleanup EXIT

# Run main function
main "$@" 