#!/usr/bin/env bash
set -e

LOG_FILE="test-output.log"

echo "🔍 Checking logs for known errors..."

# Read log file
LOG_CONTENT=$(cat "$LOG_FILE" | tr '[:upper:]' '[:lower:]')

# Network errors
if echo "$LOG_CONTENT" | grep -q "connection refused\|timeout\|504 gateway timeout"; then
    echo "⚠️ Network/Timeout Error detected – attempting auto-fix..."
    # Example network fix (simulate restart)
    sudo systemctl restart networking || true
    sleep 5
fi

# Dependency errors
if echo "$LOG_CONTENT" | grep -q "modulenotfounderror"; then
    DEP_NAME=$(grep -oP "(?<=No module named ')[^']+" "$LOG_FILE")
    echo "⚠️ Missing dependency detected: $DEP_NAME – installing..."
    pip install "$DEP_NAME" || true
    sleep 5
fi

# Out of memory
if echo "$LOG_CONTENT" | grep -q "outofmemoryerror\|java\.lang\.outofmemoryerror"; then
    echo "⚠️ Out of memory detected – cleaning cache..."
    echo 3 | sudo tee /proc/sys/vm/drop_caches || true
    sleep 5
fi

# Segmentation fault
if echo "$LOG_CONTENT" | grep -q "segmentation fault"; then
    echo "⚠️ Segmentation fault detected – retrying..."
    sleep 5
fi

# Disk full
if echo "$LOG_CONTENT" | grep -q "disk full"; then
    echo "⚠️ Disk full detected – cleaning /tmp..."
    rm -rf /tmp/* || true
    sleep 5
fi

echo "✅ Analyzer completed."

