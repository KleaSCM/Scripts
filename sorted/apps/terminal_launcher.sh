#!/bin/bash 
# @interactive
# Launch multiple terminal windows

# Script: LaunchT.sh
# Description: Terminal Launcher script
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

echo "=== Multi-Terminal Launcher ==="
gnome-terminal -- bash -c "cd ~/Documents; bash"
gnome-terminal -- bash -c "top; bash"
gnome-terminal -- bash -c "htop; bash"
gnome-terminal -- bash -c "cd ~/Projects; bash"
echo "Terminals launched!"
