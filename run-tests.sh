#!/bin/bash
set -e

MAX_RETRIES=3
RETRY_DELAY=5

echo "🧪 Running tests with self-healing retries..."

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "➡️ Attempt $attempt of $MAX_RETRIES"

    # Simulate random failures
    case $(( RANDOM % 5 )) in
        0)
            echo "ERROR: Timeout occurred during test" | tee test-output.log
            ;;
        1)
            echo "ERROR: Connection refused while connecting to DB" | tee test-output.log
            ;;
        2)
            echo "java.lang.OutOfMemoryError: Java heap space" | tee test-output.log
            ;;
        3)
            echo "Traceback (most recent call last):" > test-output.log
            echo "  File \"test_app.py\", line 1, in <module>" >> test-output.log
            echo "ModuleNotFoundError: No module named 'requests'" >> test-output.log
            ;;
        4)
            echo "ERROR: Disk full while writing logs" | tee test-output.log
            ;;
        *)
            echo "All tests passed!" | tee test-output.log
            exit 0
            ;;
    esac

    echo "🔍 Checking logs for known errors..."
    python3 analyze_logs.py || true

    echo "⚠️ Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
done

echo "❌ Tests failed after $MAX_RETRIES attempts"
exit 1

