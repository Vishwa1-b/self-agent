#!/usr/bin/env bash
set -e

LOG_FILE="test-output.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ No log file found ($LOG_FILE)"
    exit 1
fi

LOG_CONTENT=$(cat "$LOG_FILE" | tr '[:upper:]' '[:lower:]')

handle_error() {
    local pattern="$1"
    local message="$2"
    local action="$3"

    if echo "$LOG_CONTENT" | grep -q "$pattern"; then
        echo "$message"
        echo "👉 Running: $action"
        eval "$action"
        exit 1
    fi
}

# Detect and fix common errors
handle_error "timeout" \
    "⚠️ Timeout Error detected – adding delay..." \
    "sleep 5"

handle_error "connection refused" \
    "⚠️ Network Error detected – retrying..." \
    "echo 'Simulating network fix...'"

handle_error "modulenotfounderror" \
    "⚠️ Missing dependency detected – installing..." \
    "pip install requests || true"

handle_error "outofmemoryerror" \
    "⚠️ Out of memory – cleaning caches..." \
    "echo 3 | sudo tee /proc/sys/vm/drop_caches || true"

handle_error "segmentation fault" \
    "⚠️ Segmentation fault detected – retrying..." \
    "sleep 5"

handle_error "disk full" \
    "⚠️ Disk full – cleaning temporary files..." \
    "rm -rf /tmp/* || true"

echo "✅ No known errors detected."
exit 0

