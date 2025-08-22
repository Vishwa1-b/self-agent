#!/usr/bin/env python3
import sys, re, subprocess

LOG_FILE = "test-output.log"

def run_cmd(cmd):
    print(f"👉 Running: {cmd}")
    subprocess.run(cmd, shell=True, check=False)

def detect_and_fix():
    try:
        with open(LOG_FILE, "r") as f:
            log_content = f.read().lower()
    except FileNotFoundError:
        print("⚠️ No log file found.")
        sys.exit(1)

    # Error detection patterns and fixes
    error_patterns = {
        "timeout": {
            "msg": "⚠️ Timeout Error detected – retrying...",
            "fix": lambda: None  # just retry
        },
        "connection refused": {
            "msg": "⚠️ Network Error detected – restarting network services...",
            "fix": lambda: run_cmd("sudo systemctl restart networking || true")
        },
        "modulenotfounderror": {
            "msg": "⚠️ Missing dependency detected – installing package...",
            "fix": lambda: fix_missing_module(log_content)
        },
        "outofmemoryerror": {
            "msg": "⚠️ Out of memory error detected – freeing memory...",
            "fix": lambda: run_cmd("sudo sync; sudo sysctl -w vm.drop_caches=3 || true")
        },
        "segmentation fault": {
            "msg": "⚠️ Segmentation fault detected – restarting process...",
            "fix": lambda: run_cmd("pkill -f python || true")
        },
        "disk full": {
            "msg": "⚠️ Disk full error detected – cleaning temp files...",
            "fix": lambda: run_cmd("rm -rf /tmp/* || true")
        }
    }

    detected = False
    for pattern, action in error_patterns.items():
        if re.search(pattern, log_content):
            print(action["msg"])
            action["fix"]()
            detected = True

    if detected:
        sys.exit(1)  # Exit 1 so GitHub Actions retries
    else:
        print("✅ No known errors detected.")
        sys.exit(0)

def fix_missing_module(log_content: str):
    """Extract missing module from log and install it"""
    pkg_match = re.search(r"no module named ['\"]?([a-zA-Z0-9_\-]+)", log_content)
    if pkg_match:
        pkg = pkg_match.group(1)
        run_cmd(f"pip install {pkg}")
    else:
        print("⚠️ Could not detect module name from error log.")

if __name__ == "__main__":
    detect_and_fix()

