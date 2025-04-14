#!/bin/bash
# Save and restore terminal layout (tmux example)

# Script: SvTLayout.sh
# Description: Save Terminal Layout script
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

echo "=== Layout Saver ==="
tmux save-session -t my_session ~/.tmux_layout
echo "Layout saved!"
