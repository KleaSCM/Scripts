#!/bin/bash
# Script: CleanT.sh
# Description: Clean Terminal script
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

# Cleans up terminal clutter

echo "=== Terminal Cleanup ==="
echo "Killing abandoned terminals..."
killall -9 bash zsh 2>/dev/null

echo "Clearing command history..."
history -c
echo > ~/.bash_history
echo > ~/.zsh_history

echo "Resetting terminal..."
reset

echo "Cleanup complete!"
