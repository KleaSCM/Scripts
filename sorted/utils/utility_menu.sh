#!/bin/bash
# utils_ui.sh
# A cute and colorful Bash UI for utility scripts.

# Script: utility_menu.sh
# Description: Utility tools and helper functions menu
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

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
CONFIG_FILE="$CONFIG_DIR/utility_menu.conf"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${MAGENTA}"
echo "   _    _ _   _ _ _        "
echo "  | |  | | | (_) (_)       "
echo "  | |  | | |_ _| |_  __ _  "
echo "  | |  | | __| | | |/ _\` | "
echo "  | |__| | |_| | | | (_| | "
echo "   \____/ \__|_|_|_|\__,_| "
echo -e "${NC}"

# Function to display the main menu
show_menu() {
    clear
    echo -e "${BLUE}Utility Tools Menu${NC}"
    echo -e "==================="
    echo -e "1) Terminal Cleaner"
    echo -e "2) Clipboard Helper"
    echo -e "3) Terminal Launcher"
    echo -e "4) Session Manager"
    echo -e "5) Terminal Tab Manager"
    echo -e "6) Window Handler"
    echo -e "7) Terminal Layout Manager"
    echo -e "8) Exit"
    echo -e "==================="
}

# Main loop
while true; do
    show_menu
    read -p "Select an option (1-8): " choice

    case $choice in
        1)
            echo -e "${CYAN}Running Terminal Cleaner...${NC}"
            "$SCRIPT_DIR/terminal_cleaner.sh"
            ;;
        2)
            echo -e "${CYAN}Running Clipboard Helper...${NC}"
            "$SCRIPT_DIR/clipboard_helper.sh"
            ;;
        3)
            echo -e "${CYAN}Launching Terminals...${NC}"
            "$SCRIPT_DIR/terminal_launcher.sh"
            ;;
        4)
            echo -e "${CYAN}Running Session Manager...${NC}"
            "$SCRIPT_DIR/session_manager.sh"
            ;;
        5)
            echo -e "${CYAN}Running Terminal Tab Manager...${NC}"
            "$SCRIPT_DIR/terminal_tab_manager.sh"
            ;;
        6)
            echo -e "${CYAN}Running Window Handler...${NC}"
            "$SCRIPT_DIR/window_handler.sh"
            ;;
        7)
            echo -e "${CYAN}Running Terminal Layout Manager...${NC}"
            "$SCRIPT_DIR/terminal_layout_manager.sh"
            ;;
        8)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
