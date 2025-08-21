#!/bin/bash
set -e

echo "⚠️ Deployment failed. Rolling back..."

# Stop the failing container
docker stop myapp || true
docker rm myapp || true

# Rollback to last stable image (assume tagged as stable)
docker run -d -p 8080:8080 --name myapp myapp:stable

echo "✅ Rollback complete. Running stable version."

