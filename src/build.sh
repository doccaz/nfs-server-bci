#!/bin/bash
set -e

IMAGE_NAME="nfs-server-bci"
TAG="local-test"

# Check for root if using Podman locally for the run (build doesn't strictly need it, but consistent context helps)
if [ "$(id -u)" -ne 0 ] && command -v podman &> /dev/null; then
    echo "⚠️  Note: You are building as a non-root user."
    echo "    When running this image locally, you MUST use 'sudo podman run' because"
    echo "    NFS Kernel Server requires privileged kernel access."
fi

echo "🔨 Building $IMAGE_NAME:$TAG..."

# Build with Docker format for compatibility
podman build \
  --format docker \
  -t localhost/$IMAGE_NAME:$TAG \
  .

echo "✅ Build complete!"
echo "   Image: localhost/$IMAGE_NAME:$TAG"
echo "   To test run:"
echo "   sudo podman run --rm -it --privileged --net=host -e SHARED_DIRECTORY=/data localhost/$IMAGE_NAME:$TAG"
echo "   (Adjust SHARED_DIRECTORY as needed)"
