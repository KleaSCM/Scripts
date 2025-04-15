#!/bin/bash
# Fix and validate all scripts in ~/Documents/Scripts/sorted/

BASE_DIR="$HOME/Documents/Scripts/sorted"
LOG_FILE="/tmp/script_fix_log.txt"

echo "🔧 Script validation started..." | tee "$LOG_FILE"

find "$BASE_DIR" -type f -name "*.sh" | while read -r script; do
    echo "📝 Checking: $script" | tee -a "$LOG_FILE"

    # Add shebang if missing
    if ! head -n 1 "$script" | grep -qE '^#!'; then
        echo "⚠️  Missing shebang — adding #!/bin/bash to $script" | tee -a "$LOG_FILE"
        sed -i '1i #!/bin/bash' "$script"
    fi

    # Ensure executable
    if [ ! -x "$script" ]; then
        chmod +x "$script"
        echo "✅ Made executable: $script" | tee -a "$LOG_FILE"
    fi
done

echo "🎉 Done! Logs at: $LOG_FILE"
