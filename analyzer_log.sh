#!/usr/bin/env bash
set -e

LOG_FILE="test-output.log"

echo "🔍 Checking logs for known errors..."

# Read log content
if [ ! -f "$LOG_FILE" ]; then
    echo "⚠️ Log file not found: $LOG_FILE"
    exit 1
fi

LOG_CONTENT=$(cat "$LOG_FILE" | tr '[:upper:]' '[:lower:]')

# Auto-fix errors
if echo "$LOG_CONTENT" | grep -q "modulenotfounderror"; then
    echo "⚠️ Missing dependency detected – installing..."
    python -m pip install requests || true
fi

if echo "$LOG_CONTENT" | grep -q "timeout"; then
    echo "⚠️ Timeout Error detected – adding delay..."
    sleep 5
fi

if echo "$LOG_CONTENT" | grep -q "connection refused"; then
    echo "⚠️ Network Error detected – retrying network operations..."
    sudo systemctl restart networking || true
fi

if echo "$LOG_CONTENT" | grep -q "outofmemoryerror"; then
    echo "⚠️ Out of memory error detected – simulating memory cleanup..."
    echo 3 | sudo tee /proc/sys/vm/drop_caches || true
    sleep 5
fi

if echo "$LOG_CONTENT" | grep -q "segmentation fault"; then
    echo "⚠️ Segmentation fault detected – cannot auto-fix"
fi

if echo "$LOG_CONTENT" | grep -q "disk full"; then
    echo "⚠️ Disk full error detected – cleaning /tmp..."
    rm -rf /tmp/* || true
fi

echo "✅ Analyzer completed."

