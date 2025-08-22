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
        exit 1  # force retry
    fi
}

# Error detection & auto-fix
handle_error "timeout" \
    "⚠️ Timeout Error detected – adding delay & retrying..." \
    "sleep 5"

handle_error "connection refused" \
    "⚠️ Network Error detected – restarting network services..." \
    "sudo systemctl restart networking || true"

handle_error "modulenotfounderror" \
    "⚠️ Missing dependency detected – auto-installing..." \
    "pip install $(grep -oP '(?<=No module named ).*' $LOG_FILE | tr -d \"'\") || true"

handle_error "outofmemoryerror" \
    "⚠️ Out of memory detected – cleaning up memory caches..." \
    "echo 3 | sudo tee /proc/sys/vm/drop_caches || true && sleep 5"

handle_error "segmentation fault" \
    "⚠️ Segmentation fault detected – retrying..." \
    "sleep 5"

handle_error "disk full" \
    "⚠️ Disk full detected – cleaning temporary files..." \
    "rm -rf /tmp/* || true"

handle_error "image not found" \
    "⚠️ Missing Docker image – pulling stable fallback image..." \
    "docker pull myapp:stable || true"

handle_error "pull access denied" \
    "⚠️ Docker registry access denied – logging in with credentials..." \
    "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin || true"

echo "✅ No known errors detected in logs."
exit 0

