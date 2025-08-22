#!/usr/bin/env python3
import sys
import re
import subprocess

LOG_FILE = "test-output.log"

def run_cmd(cmd):
    print(f"👉 Running: {cmd}")
    subprocess.run(cmd, shell=True, check=False)

def detect_and_fix():
    try:
        with open(LOG_FILE, "r") as f:
            log_content = f.read().lower()
    except FileNotFoundError:
        print("❌ Log file not found.")
        sys.exit(1)

    # Error detection patterns + GitHub Actions friendly fixes
    error_patterns = {
        "timeout": "⚠️ Timeout Error detected – adding delay & retrying...",
        "connection refused": "⚠️ Network Error detected – retrying after short delay...",
        "modulenotfounderror": "⚠️ Missing dependency detected – reinstalling dependency...",
        "outofmemoryerror": "⚠️ Out of memory error detected – simulating memory cleanup...",
        "segmentation fault": "⚠️ Segmentation fault detected – retrying...",
        "disk full": "⚠️ Disk full error detected – simulating cleanup..."
    }

    for pattern, message in error_patterns.items():
        if re.search(pattern, log_content):
            print(message)

            # GitHub Actions–safe fixes
            if pattern == "timeout":
                run_cmd("sleep 5")   # simulate retry after wait

            elif pattern == "connection refused":
                run_cmd("ping -c 1 8.8.8.8 || true")  # check connectivity
                run_cmd("sleep 5")   # wait before retry

            elif pattern == "modulenotfounderror":
                # Try to install missing module dynamically (instead of requirements.txt)
                missing = re.findall(r"no module named '([^']+)'", log_content)
                if missing:
                    for pkg in missing:
                        print(f"📦 Installing missing package: {pkg}")
                        run_cmd(f"pip install {pkg}")

            elif pattern == "outofmemoryerror":
                run_cmd("echo 3 | sudo tee /proc/sys/vm/drop_caches || true")  # safe fallback
                run_cmd("sleep 5")

            elif pattern == "segmentation fault":
                run_cmd("sleep 3")  # just retry

            elif pattern == "disk full":
                run_cmd("df -h")  # show usage
                run_cmd("rm -rf ~/.cache || true")  # free some space

            # Exit with failure so workflow retries
            sys.exit(1)

    print("✅ No known errors detected.")
    sys.exit(0)

if __name__ == "__main__":
    detect_and_fix()

