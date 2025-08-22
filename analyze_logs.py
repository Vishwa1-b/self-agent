#!/usr/bin/env python3
import sys
import re
import subprocess

LOG_FILE = "test-output.log"

def run_cmd(cmd):
    print(f"👉 Running: {cmd}")
    subprocess.run(cmd, shell=True, check=False)

def detect_and_fix():
    with open(LOG_FILE, "r") as f:
        log_content = f.read().lower()

    # Common error patterns
    error_patterns = {
        "timeout": "⚠️ Timeout Error detected – adding delay & retrying...",
        "connection refused": "⚠️ Network Error detected – restarting network services...",
        "outofmemoryerror": "⚠️ Out of memory error detected – simulating cleanup...",
        "segmentation fault": "⚠️ Segmentation fault detected – retrying...",
        "disk full": "⚠️ Disk full error detected – simulating cleanup..."
    }

    # Check generic patterns first
    for pattern, message in error_patterns.items():
        if re.search(pattern, log_content):
            print(message)
            if pattern == "timeout":
                run_cmd("sleep 5")
            elif pattern == "connection refused":
                run_cmd("sudo systemctl restart networking || true")
            elif pattern == "outofmemoryerror":
                run_cmd("echo 3 | sudo tee /proc/sys/vm/drop_caches || true")
                run_cmd("sleep 5")
            elif pattern == "disk full":
                run_cmd("rm -rf /tmp/* || true")
            # Exit with failure so retry happens
            sys.exit(1)

    # 🔍 Detect missing dependencies dynamically
    match = re.search(r"modulenotfounderror:\s*no module named '([\w\-]+)'", log_content, re.I)
    if match:
        missing_pkg = match.group(1)
        print(f"⚠️ Missing dependency detected: {missing_pkg} – installing automatically...")
        run_cmd(f"pip install {missing_pkg}")
        sys.exit(1)

    print("✅ No known errors detected.")
    sys.exit(0)

if __name__ == "__main__":
    detect_and_fix()

