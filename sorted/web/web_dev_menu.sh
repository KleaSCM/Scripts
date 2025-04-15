#!/bin/bash
# @interactive

# Script: web_dev_menu.sh
# Description: Web development tools and utilities menu
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, nodejs, npm, git

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
CONFIG_FILE="$CONFIG_DIR/web_dev_menu.conf"

# ... existing code ... 