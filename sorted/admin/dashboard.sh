#!/bin/bash

# Script: dashboard.sh
# Description: Advanced script management system dashboard
# Author: KleaSCM
# Version: 2.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0, notify-send, mpv, sensors, htop, nmcli

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
CONFIG_FILE="$CONFIG_DIR/dashboard.conf"
FAVORITES_FILE="$CONFIG_DIR/favorites.conf"
HISTORY_FILE="$CONFIG_DIR/history.log"
THEME_FILE="$CONFIG_DIR/theme.conf"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"
LOGS_DIR="$SCRIPT_DIR/../logs"

# Load configuration
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$THEME_FILE" ]] && source "$THEME_FILE"
    
    # Default settings
    NOTIFICATIONS=${NOTIFICATIONS:-true}
    SOUND_EFFECTS=${SOUND_EFFECTS:-true}
    THEME=${THEME:-"default"}
    REFRESH_RATE=${REFRESH_RATE:-5}
}

# Colors and Theme
load_theme() {
    case "$THEME" in
        "dark")
            BG='\033[40m'
            FG='\033[37m'
            ACCENT='\033[36m'
            WARNING='\033[33m'
            ERROR='\033[31m'
            SUCCESS='\033[32m'
            ;;
        "light")
            BG='\033[47m'
            FG='\033[30m'
            ACCENT='\033[34m'
            WARNING='\033[33m'
            ERROR='\033[31m'
            SUCCESS='\033[32m'
            ;;
        *)
            BG='\033[0m'
            FG='\033[0m'
            ACCENT='\033[36m'
            WARNING='\033[33m'
            ERROR='\033[31m'
            SUCCESS='\033[32m'
            ;;
    esac
    NC='\033[0m'
}

# Sound effects
play_sound() {
    [[ "$SOUND_EFFECTS" == "true" ]] && {
        case "$1" in
            "success") mpv --no-video --quiet "$SOUNDS_DIR/success.mp3" &>/dev/null & ;;
            "error") mpv --no-video --quiet "$SOUNDS_DIR/error.mp3" &>/dev/null & ;;
            "notification") mpv --no-video --quiet "$SOUNDS_DIR/notification.mp3" &>/dev/null & ;;
        esac
    }
}

# Notifications
send_notification() {
    [[ "$NOTIFICATIONS" == "true" ]] && {
        notify-send -u "$1" "Script Dashboard" "$2"
    }
}

# Enhanced System Status
show_system_status() {
    echo -e "${ACCENT}=== System Status ===${NC}"
    
    # CPU and Memory
    echo -e "${FG}CPU Usage:${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8 "%"}')"
    echo -e "${FG}Memory Usage:${NC} $(free -h | awk '/Mem/ {print $3 " / " $2}')"
    
    # Disk Usage
    echo -e "${FG}Disk Usage:${NC}"
    df -h | grep -v "tmpfs" | awk '{print $1 " " $5 " " $3 " / " $2}' | while read -r line; do
        echo -e "  ${FG}$line${NC}"
    done
    
    # Network Status
    echo -e "${FG}Network:${NC}"
    nmcli device status | grep -v "DEVICE" | while read -r line; do
        echo -e "  ${FG}$line${NC}"
    done
    
    # Temperature
    if command -v sensors &>/dev/null; then
        echo -e "${FG}Temperature:${NC}"
        sensors | grep "Core" | while read -r line; do
            echo -e "  ${FG}$line${NC}"
        done
    fi
    
    # Battery (if available)
    if [[ -d "/sys/class/power_supply/BAT0" ]]; then
        echo -e "${FG}Battery:${NC} $(cat /sys/class/power_supply/BAT0/capacity)%"
    fi
    
    echo
}

# Process Monitoring
show_process_monitor() {
    echo -e "${ACCENT}=== Top Processes ===${NC}"
    ps aux --sort=-%cpu | head -n 6 | awk '{printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $11}'
    echo
}

# Script Search
search_scripts() {
    local query="$1"
    find "$SCRIPT_DIR/.." -type f -name "*.sh" -exec grep -l "$query" {} \;
}

# Recent History
show_recent_history() {
    echo -e "${ACCENT}=== Recent Activity ===${NC}"
    tail -n 10 "$HISTORY_FILE" 2>/dev/null || echo "No history available"
    echo
}

# Favorites Management
manage_favorites() {
    local script="$1"
    if grep -q "^$script$" "$FAVORITES_FILE" 2>/dev/null; then
        sed -i "/^$script$/d" "$FAVORITES_FILE"
        echo "Removed from favorites"
    else
        echo "$script" >> "$FAVORITES_FILE"
        echo "Added to favorites"
    fi
}

# Script Scheduling
schedule_script() {
    local script="$1"
    local time="$2"
    local frequency="$3"
    
    case "$frequency" in
        "once") echo "at $time $script" | at now + "$time" ;;
        "daily") echo "0 $time * * * $script" | crontab - ;;
        "weekly") echo "0 $time * * 0 $script" | crontab - ;;
        "monthly") echo "0 $time 1 * * $script" | crontab - ;;
    esac
}

# System Health Check
run_health_check() {
    echo -e "${ACCENT}=== System Health Check ===${NC}"
    
    # Check disk space
    df -h | awk '$5 > 90 {print "WARNING: " $1 " is " $5 " full"}'
    
    # Check memory usage
    free -h | awk '/Mem/ {if($3/$2 * 100 > 90) print "WARNING: High memory usage"}'
    
    # Check CPU temperature
    if command -v sensors &>/dev/null; then
        sensors | awk '/Core/ {if($3 > 80) print "WARNING: High CPU temperature"}'
    fi
    
    # Check network connectivity
    ping -c 1 8.8.8.8 &>/dev/null || echo "WARNING: No internet connectivity"
    
    echo
}

# ASCII Art Header
show_header() {
    echo -e "${ACCENT}"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠳⠶⣤⡄⠀⠀⠀⠀⠀⢀⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡇⠀⠀⣸⠃⠀⠀⠀⠀⣴⠟⠁⠈⢻⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⢠⡟⠀⠀⠀⢠⡾⠃⠀⠀⣰⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠓⠾⠁⠀⠀⣰⠟⠀⠀⢀⡾⠋⠀⠀⠀⢀⣴⣆⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣠⣤⣤⣤⣄⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠙⠳⣦⣴⠟⠁⠀⠀⣠⡴⠋⠀⠈⢷⣄⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣿⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⣿⣿⣿⣿⣷⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⢀⣴⠟⠁⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⣿⣿⡿⠟⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠙⠻⢿⣿⣿⣶⣄⡀⠀⠀⠀⠺⣏⠀⠀⣀⡴⠟⠁⢀⣀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⠿⠋⠁⠀⢀⣴⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢶⣬⡙⠿⣿⣿⣶⣄⠀⠀⠙⢷⡾⠋⢀⣤⠾⠋⠙⢷⡀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⡿⠋⠁⠀⠀⠀⢠⣾⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣦⣠⣤⠽⣿⣦⠈⠙⢿⣿⣷⣄⠀⠀⠀⠺⣏⠁⠀⠀⣀⣼⠿⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⡿⠋⠀⠀⠀⠀⠀⣰⣿⠟⠀⠀⠀⢠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⣿⣧⠀⠀⠈⢿⣷⣄⠀⠙⢿⣿⣷⣄⠀⠀⠙⣧⡴⠟⠋⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠏⠀⠀⠀⠀⠀⠀⢷⣿⡟⠀⣰⡆⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⣿⣿⡀⠀⠀⠈⢿⣿⣦⠀⠀⠙⢿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⣼⣿⡿⠁⠀⠦⣤⣀⠀⠀⢀⣿⣿⡇⢰⣿⠇⠀⢸⣿⡆⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⢸⣿⣿⣆⠀⠀⠈⣿⣿⣧⣠⣤⠾⢿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⣸⣿⣿⣵⣿⠀⠀⠀⠉⠀⠀⣼⣿⢿⡇⣾⣿⠀⠀⣾⣿⡇⢸⠀⠀⠀⠀⠀⠀⣿⡇⠀⣼⣿⢻⣿⣦⠴⠶⢿⣿⣿⣇⠀⠀⠀⢻⣿⣧⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⢀⣿⣿⣿⣿⠇⠀⠀⠀⠀⠀⢠⣿⡟⡌⣼⣿⣿⠉⢁⣿⣿⣷⣿⡗⠒⠚⠛⠛⢛⣿⣯⣯⣿⣿⠀⢻⣿⣧⠀⢸⣿⣿⣿⡄⠀⠀⠀⠙⢿⣿⣷⣤⣀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⢸⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⢸⣿⡇⣼⣿⣿⣿⣶⣾⣿⣿⢿⣿⡇⠀⠀⠀⠀⢸⣿⠟⢻⣿⣿⣿⣶⣿⣿⣧⢸⣿⣿⣿⣧⠀⠀⠀⢰⣷⡈⠛⢿⣿⣿⣶⣦⣤⣤⣀"
    echo "⠀⠀⠀⢀⣤⣾⣿⣿⢫⡄⠀⠀⠀⠀⠀⠀⣿⣿⣹⣿⠏⢹⣿⣿⣿⣿⣿⣼⣿⠃⠀⠀⠀⢀⣿⡿⢀⣿⣿⠟⠀⠀⠀⠹⣿⣿⣿⠇⢿⣿⡄⠀⠀⠈⢿⣿⣷⣶⣶⣿⣿⣿⣿⣿⡿"
    echo "⣴⣶⣶⣿⣿⣿⣿⣋⣴⣿⣇⠀⠀⠀⠀⠀⢀⣿⣿⣿⣟⣴⠟⢿⣿⠟⣿⣿⣿⣿⣶⣶⣶⣶⣾⣿⣿⣿⠿⣫⣤⣶⡆⠀⠀⣻⣿⣿⣶⣸⣿⣷⡀⠀⠀⠸⣿⣿⣿⡟⠛⠛⠛⠉⠁⠀"
    echo "⠻⣿⣿⣿⣿⣿⣿⡿⢿⣿⠋⠀⢠⠀⠀⠀⢸⣿⣿⣿⣿⣁⣀⣀⣁⠀⠀⠉⠉⠉⠉⠉⠉⠉⠁⠀⠀⠀⠸⢟⣫⣥⣶⣿⣿⣿⠿⠟⠋⢻⣿⡟⣇⣠⡤⠀⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠉⠉⢹⣿⡇⣾⣿⠀⠀⢸⡆⠀⠀⢸⣿⣿⡟⠿⠿⠿⠿⣿⣿⣿⣿⣷⣦⡄⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣯⣥⣤⣄⣀⡀⢸⣿⠇⢿⢸⡇⠀⢹⣿⣿⣿⡇⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⣾⣿⡇⣿⣿⠀⠀⠸⣧⠀⠀⢸⣿⣿⠀⢀⣀⣤⣤⣶⣾⣿⠿⠟⠛⠁⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠙⠛⢛⣛⠛⠛⠛⠃⠸⣿⣆⢸⣿⣇⠀⢸⣿⣿⣿⣷⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⢻⣿⡇⢻⣿⡄⠀⠀⣿⡄⠀⢸⣿⡷⢾⣿⠿⠟⠛⠉⠉⠀⠀⠀⢠⣶⣾⣿⣿⣿⣿⣿⣶⣶⠀⠀⢀⡾⠋⠁⢠⡄⠀⣤⠀⢹⣿⣦⣿⡇⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⢸⣿⣇⢸⣿⡇⠀⠀⣿⣧⠀⠈⣿⣷⠀⠀⢀⣀⠀⢙⣧⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢀⣿⡏⠀⠀⠸⣇⠀⠀⠘⠛⠘⠛⠀⢀⣿⣿⣿⡇⠀⣼⣿⢻⣿⡿⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠸⣿⣿⣸⣿⣿⠀⠀⣿⣿⣆⠀⢿⣿⡀⠀⠸⠟⠀⠛⣿⠃⠀⠀⢸⣿⡇⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠙⠷⣦⣄⡀⠀⢀⣴⣿⡿⣱⣾⠁⠀⣿⣿⣾⣿⡇⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣇⠀⢿⢹⣿⣆⢸⣿⣧⣀⠀⠀⠴⠞⠁⠀⠀⠀⠸⣿⡇⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⢀⣨⣽⣾⣿⣿⡏⢀⣿⣿⠀⣸⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣆⢸⡏⠻⣿⣦⣿⣿⣿⣿⣶⣦⣤⣀⣀⣀⣀⠀⣿⣷⠀⠀⠀⣸⣿⣏⣀⣤⣤⣶⣾⣿⣿⣿⠿⠛⢹⣿⣧⣼⣿⣿⣰⣿⣿⠛⠛⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠙⣿⣿⣦⣷⠀⢻⣿⣿⣿⣿⡝⠛⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠟⠛⠛⠉⠁⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣄⢸⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⠟⠻⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⡌⠙⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${NC}"
}

# Main Menu Loop
main_menu() {
    while true; do
        clear
        show_header
        show_system_status
        show_process_monitor
        show_recent_history
        
        echo -e "${ACCENT}=== Main Dashboard ===${NC}"
        echo -e "${FG}1. ${ACCENT}System Tools${NC} (System management and diagnostics)"
        echo -e "${FG}2. ${ACCENT}Development${NC} (Project setup and development tools)"
        echo -e "${FG}3. ${ACCENT}Web Development${NC} (Web project setup and tools)"
        echo -e "${FG}4. ${ACCENT}Utilities${NC} (Terminal and system utilities)"
        echo -e "${FG}5. ${ACCENT}Applications${NC} (Application launchers and managers)"
        echo -e "${FG}6. ${ACCENT}Script Management${NC} (Search, favorites, history)"
        echo -e "${FG}7. ${ACCENT}System Health${NC} (Health checks and monitoring)"
        echo -e "${FG}8. ${ACCENT}Settings${NC} (Configuration and customization)"
        echo -e "${ERROR}9. Exit${NC}"
        echo
        
        read -p "Choose an option: " CHOICE
        
        case $CHOICE in
            1) "$SCRIPT_DIR/system_ui.sh" ;;
            2) show_development_menu ;;
            3) show_web_development_menu ;;
            4) "$SCRIPT_DIR/../utils/utility_menu.sh" ;;
            5) "$SCRIPT_DIR/../apps/terminal_launcher.sh" ;;
            6) show_script_management_menu ;;
            7) show_system_health_menu ;;
            8) show_settings_menu ;;
            9) exit 0 ;;
            *) echo -e "${ERROR}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Submenus
show_development_menu() {
    while true; do
        clear
        echo -e "${ACCENT}=== Development Tools ===${NC}"
        select dev_tool in "C++ Project Setup" "Go Project Setup" "Python Project Setup" "Back"; do
            case $dev_tool in
                "C++ Project Setup") "$SCRIPT_DIR/../dev/cpp_project_setup.sh" ;;
                "Go Project Setup") "$SCRIPT_DIR/../dev/go_project_setup.sh" ;;
                "Python Project Setup") "$SCRIPT_DIR/../dev/python_project_setup.sh" ;;
                "Back") return ;;
            esac
        done
    done
}

show_web_development_menu() {
    while true; do
        clear
        echo -e "${ACCENT}=== Web Development Tools ===${NC}"
        select web_tool in "Flask Project Setup" "HTML Project Setup" "Back"; do
            case $web_tool in
                "Flask Project Setup") "$SCRIPT_DIR/../web/flask_project_setup.sh" ;;
                "HTML Project Setup") "$SCRIPT_DIR/../web/html_project_setup.sh" ;;
                "Back") return ;;
            esac
        done
    done
}

show_script_management_menu() {
    while true; do
        clear
        echo -e "${ACCENT}=== Script Management ===${NC}"
        select action in "Search Scripts" "View Favorites" "View History" "Schedule Script" "Back"; do
            case $action in
                "Search Scripts")
                    read -p "Enter search query: " query
                    search_scripts "$query"
                    read -p "Press Enter to continue..."
                    ;;
                "View Favorites")
                    cat "$FAVORITES_FILE" 2>/dev/null || echo "No favorites"
                    read -p "Press Enter to continue..."
                    ;;
                "View History")
                    show_recent_history
                    read -p "Press Enter to continue..."
                    ;;
                "Schedule Script")
                    read -p "Enter script path: " script
                    read -p "Enter time (e.g., 2 hours): " time
                    read -p "Enter frequency (once/daily/weekly/monthly): " frequency
                    schedule_script "$script" "$time" "$frequency"
                    ;;
                "Back") return ;;
            esac
        done
    done
}

show_system_health_menu() {
    while true; do
        clear
        echo -e "${ACCENT}=== System Health ===${NC}"
        select action in "Run Health Check" "View System Logs" "Monitor Resources" "Back"; do
            case $action in
                "Run Health Check")
                    run_health_check
                    read -p "Press Enter to continue..."
                    ;;
                "View System Logs")
                    journalctl -n 50
                    read -p "Press Enter to continue..."
                    ;;
                "Monitor Resources")
                    htop
                    ;;
                "Back") return ;;
            esac
        done
    done
}

show_settings_menu() {
    while true; do
        clear
        echo -e "${ACCENT}=== Settings ===${NC}"
        select setting in "Change Theme" "Toggle Notifications" "Toggle Sound Effects" "Set Refresh Rate" "Back"; do
            case $setting in
                "Change Theme")
                    select theme in "default" "dark" "light"; do
                        sed -i "s/THEME=.*/THEME=\"$theme\"/" "$CONFIG_FILE"
                        load_theme
                        break
                    done
                    ;;
                "Toggle Notifications")
                    [[ "$NOTIFICATIONS" == "true" ]] && NOTIFICATIONS="false" || NOTIFICATIONS="true"
                    sed -i "s/NOTIFICATIONS=.*/NOTIFICATIONS=\"$NOTIFICATIONS\"/" "$CONFIG_FILE"
                    ;;
                "Toggle Sound Effects")
                    [[ "$SOUND_EFFECTS" == "true" ]] && SOUND_EFFECTS="false" || SOUND_EFFECTS="true"
                    sed -i "s/SOUND_EFFECTS=.*/SOUND_EFFECTS=\"$SOUND_EFFECTS\"/" "$CONFIG_FILE"
                    ;;
                "Set Refresh Rate")
                    read -p "Enter refresh rate in seconds: " rate
                    sed -i "s/REFRESH_RATE=.*/REFRESH_RATE=\"$rate\"/" "$CONFIG_FILE"
                    ;;
                "Back") return ;;
            esac
        done
    done
}

# Initialize
load_config
load_theme
main_menu 