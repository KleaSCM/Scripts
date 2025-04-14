#!/bin/bash
# Script: WH.sh
# Description: Window Handler script
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

echo "=== Workspace Setup ==="
gnome-terminal -- bash -c "cd ~/Projects/my_project; vim; bash"
gnome-terminal -- bash -c "cd ~/Projects/my_project; git status; bash"
gnome-terminal -- bash -c "cd ~/Projects/my_project; ./run_server.sh; bash"
echo "Workspace ready!"
