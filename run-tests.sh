#!/usr/bin/env bash
set -e

MAX_RETRIES=3
RETRY_DELAY=5
LOG_FILE="test-output.log"
FAKE_ERROR_FILE=".fake_error_done"

echo "🧪 Running tests with self-healing retries..."

# Ensure pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "⚠️ pytest not found – installing automatically..."
    python -m pip install --upgrade pip
    python -m pip install pytest
fi

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "➡️ Attempt $attempt of $MAX_RETRIES"

    # Inject fake dependency error only once
    if [ ! -f "$FAKE_ERROR_FILE" ]; then
        echo "ERROR: ModuleNotFoundError: No module named 'requests'" | tee $LOG_FILE
        touch "$FAKE_ERROR_FILE"
        echo "⚠️ Injected fake dependency error for testing..."
        
        # Run analyzer but DO NOT fail the step
        ./analyzer_log.sh || true
        
        echo "⚠️ Auto-corrected missing dependency. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        continue
    fi

    # Run real tests
    pytest tests/ | tee $LOG_FILE
    EXIT_CODE=${PIPESTATUS[0]}

    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Tests passed on attempt $attempt"
        exit 0
    fi

    # Analyze logs and auto-fix errors
    ./analyzer_log.sh || true

    echo "⚠️ Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
done

echo "❌ Tests failed after $MAX_RETRIES attempts"
exit 1

