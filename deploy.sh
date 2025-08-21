#!/bin/bash
set -e  # exit immediately if a command fails

echo "🚀 Starting deployment..."

# Example: build docker image & deploy
docker build -t myapp:latest .
docker run -d -p 8080:8080 --name myapp myapp:latest

echo "✅ Deployment successful!"

