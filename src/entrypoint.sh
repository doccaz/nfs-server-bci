#!/bin/bash
set -e

SHARED_DIRECTORY="${SHARED_DIRECTORY:-/data}"
# Default to allow everyone if not specified
ALLOWED_CLIENTS="${ALLOWED_CLIENTS:-*}"

function shutdown_nfs() {
    echo "Stopping NFS services..."
    /usr/sbin/exportfs -uav
    /usr/sbin/rpc.nfsd 0
    exit 0
}

# Trap termination signals for graceful shutdown
trap shutdown_nfs SIGTERM SIGINT

echo "Starting SUSE NFS Server on SLE BCI..."

# --- KERNEL MOUNT CHECK ---
# The kernel NFS server requires the nfsd filesystem to be mounted.
# We use grep to check /proc/mounts to avoid dependency on 'mountpoint' command.
mkdir -p /proc/fs/nfsd
if ! grep -qs "nfsd" /proc/mounts; then
    echo "Mounting nfsd filesystem..."
    mount -t nfsd nfsd /proc/fs/nfsd
fi

mkdir -p "$SHARED_DIRECTORY"

# --- EXPORT CONFIGURATION ---
echo "Configuring exports for clients: $ALLOWED_CLIENTS"
# Format: /path  client(options)
# fsid=0 allows mounting the root at /
echo "$SHARED_DIRECTORY $ALLOWED_CLIENTS(rw,fsid=0,no_subtree_check,no_root_squash,insecure,sync)" > /etc/exports

mkdir -p /run/rpc_pipefs /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery

echo "Starting rpcbind..."
/sbin/rpcbind

echo "Exporting filesystems..."
exportfs -r

echo "Starting nfsd..."
# Start NFS Daemon (SLES 16/ALP defaults to v3/v4; removed -N 2 flag)
/usr/sbin/rpc.nfsd --debug 8

echo "Starting mountd..."
/usr/sbin/rpc.mountd --debug all --foreground &

# --- OUTPUT CONFIGURATION INFO ---
HOST_IP=${NODE_IP:-"detecting..."}

# If NODE_IP wasn't passed, try to guess (fallback)
if [ "$HOST_IP" = "detecting..." ]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "=================================================================="
echo "✅ NFS Server is Ready!"
echo "Use the following settings for your StorageClass parameters:"
echo "=================================================================="
echo "parameters:"
echo "  server: $HOST_IP"
echo "  share:  $SHARED_DIRECTORY"
echo "  subDir: \${pvc.metadata.namespace}/\${pvc.metadata.name}  # Recommended"
echo "=================================================================="
echo ""

# Wait for the background process to finish (allows signal trapping)
wait $!