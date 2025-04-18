#!/bin/bash
# @interactive
# Script: system_ui.sh
# Description: System management and diagnostics interface
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, notify-send

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
CONFIG_FILE="$CONFIG_DIR/system_ui.conf"

# systems_ui.sh
# A cute and colorful Bash UI for system-level scripts.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${MAGENTA}"
echo "   ____                  _              "
echo "  / ___| ___   ___   __| | ___ _ __ ___"
echo " | |  _ / _ \ / _ \ / _\` |/ _ \ '__/ __|"
echo " | |_| | (_) | (_) | (_| |  __/ |  \__ \\"
echo "  \____|\___/ \___/ \__,_|\___|_|  |___/"
echo -e "${NC}"

# Main Menu Loop
while true; do
    echo -e "${YELLOW}=== System Tools Menu ===${NC}"
    echo -e "${GREEN}1. ${CYAN}Goddess Script${NC} (Take full control of files and directories)"
    echo -e "${GREEN}2. ${CYAN}OS Diagnostics${NC} (Check system health and resources)"
    echo -e "${GREEN}3. ${CYAN}Troubleshooting UI${NC} (Navigate various troubleshooting tools)"
    echo -e "${RED}4. Exit${NC}"
    echo

    # Prompt for Choice
    read -p "Choose an option: " CHOICE

    case $CHOICE in
        1)
            echo -e "${CYAN}Running Goddess Script...${NC}"
            ./permission_manager.sh
            ;;
        2)
            echo -e "${CYAN}Running OS Diagnostics...${NC}"
            ./system_diagnostics.sh
            ;;
        3)
            echo -e "${CYAN}Launching Troubleshooting UI...${NC}"
            ./troubleshooter_ui.sh
            ;;
        4)
            echo -e "${RED}Exiting System Tools Menu. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
