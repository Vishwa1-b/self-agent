#!/bin/bash
set -e

MAX_RETRIES=3
RETRY_DELAY=3
LOG_FILE="test-output.log"

echo "🧪 Running tests with self-healing retries..."

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "➡️ Attempt $attempt of $MAX_RETRIES"
    rm -f $LOG_FILE

    # 🔀 Simulate random error or success
    case $(( RANDOM % 6 )) in
        0)
            echo "ERROR: Timeout occurred during test" | tee $LOG_FILE
            ;;
        1)
            echo "ERROR: Connection refused while connecting to DB" | tee $LOG_FILE
            ;;
        2)
            echo "Traceback (most recent call last):" > $LOG_FILE
            echo "ModuleNotFoundError: No module named 'requests'" >> $LOG_FILE
            ;;
        3)
            echo "java.lang.OutOfMemoryError: Java heap space" | tee $LOG_FILE
            ;;
        4)
            echo "Segmentation fault (core dumped)" | tee $LOG_FILE
            ;;
        5)
            echo "ERROR: Disk full while writing logs" | tee $LOG_FILE
            ;;
        *)
            echo "All tests passed!" | tee $LOG_FILE
            exit 0
            ;;
    esac

    # 🔍 Analyze logs and auto-fix
    python3 analyze_logs.py
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ No known errors, exiting."
        exit 0
    else
        echo "⚠️ Detected recoverable error. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi
done

echo "❌ Tests failed after $MAX_RETRIES attempts"
exit 1

