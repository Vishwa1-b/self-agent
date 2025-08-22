#!/usr/bin/env bash
set -e

echo "⚠️ Deployment failed. Rolling back..."

# Stop and remove old containers safely
docker rm -f myapp || true

# Deploy stable version
if docker pull myapp:stable; then
    echo "✅ Pulled stable version of app"
    docker run -d --name myapp -p 8080:8080 myapp:stable
    echo "✅ Rollback successful – running stable version"
else
    echo "❌ Rollback failed – could not pull stable image"
    exit 1
fi

