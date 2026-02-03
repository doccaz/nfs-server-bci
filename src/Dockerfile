# Use the official SLE 16 Base Image
FROM registry.suse.com/bci/bci-base:16.0

# Updated URL as requested
LABEL org.opencontainers.image.source="https://github.com/doccaz/nfs-server-bci"
LABEL org.opencontainers.image.description="NFS Server based on SLE 16 BCI"

# Install NFS kernel server and util-linux (for 'mount')
# We also include iproute2 which is often helpful for debugging network
RUN zypper --non-interactive install --no-recommends nfs-kernel-server util-linux iproute2 && \
    zypper clean -a

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 2049/tcp
ENTRYPOINT ["/entrypoint.sh"]