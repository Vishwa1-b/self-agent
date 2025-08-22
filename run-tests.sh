#!/bin/bash
set -e

MAX_RETRIES=3
RETRY_DELAY=5

echo "🧪 Running tests with self-healing retries..."

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "➡️ Attempt $attempt of $MAX_RETRIES"
    
    # Run pytest and capture output
    OUTPUT=$(pytest tests/ 2>&1) || true
    EXIT_CODE=$?

    # Check for success
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Tests passed on attempt $attempt"
        exit 0
    fi

    # Detect transient / common recoverable errors
    if echo "$OUTPUT" | grep -qi "timeout\|504 Gateway Timeout\|connection refused"; then
        echo "⚠️ Detected transient network error. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    elif echo "$OUTPUT" | grep -qi "500 Internal Server Error"; then
        echo "⚠️ Detected server error. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    elif echo "$OUTPUT" | grep -qi "ModuleNotFoundError"; then
        echo "⚠️ Missing dependency detected. Attempting reinstall..."
        pip install -r requirements.txt
        sleep $RETRY_DELAY
        continue
    elif echo "$OUTPUT" | grep -qi "OutOfMemoryError"; then
        echo "⚠️ Out of memory error detected. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    elif echo "$OUTPUT" | grep -qi "Segmentation fault"; then
        echo "⚠️ Segmentation fault detected. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    elif echo "$OUTPUT" | grep -qi "disk full"; then
        echo "⚠️ Disk full error detected. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    fi

    # If error not recoverable → fail immediately
    echo "❌ Tests failed with non-recoverable error:"
    echo "$OUTPUT"
    exit 1
done

# If retries exhausted
echo "❌ Tests failed after $MAX_RETRIES attempts"
exit 1

