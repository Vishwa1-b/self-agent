#!/usr/bin/env bash
set -e

MAX_RETRIES=3
RETRY_DELAY=5
LOG_FILE="test-output.log"

echo "🧪 Running tests with self-healing retries..."

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "➡️ Attempt $attempt of $MAX_RETRIES"

    # Run tests and capture logs
    pytest tests/ | tee $LOG_FILE
    EXIT_CODE=${PIPESTATUS[0]}

    # If success
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Tests passed on attempt $attempt"
        exit 0
    fi

    echo "🔍 Checking logs for known errors..."
    ./analyzer_log.sh

    echo "⚠️ Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
done

# Final failure
echo "❌ Tests failed after $MAX_RETRIES attempts"
echo "⚠️ Initiating rollback..."
./rollback.sh
exit 1

