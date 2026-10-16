#!/bin/bash
# download_bazzite_iso.sh - Downloads Bazzite Deck NVIDIA ISO with multi-connection acceleration
set -e

ISO_DIR="/mnt/vm-storage/proxmox-data/template/iso"
ISO_NAME="bazzite-deck-nvidia-stable-amd64.iso"
URL="https://download.bazzite.gg/${ISO_NAME}"

mkdir -p "$ISO_DIR"

echo "=== Downloading Bazzite Deck NVIDIA ISO ==="
echo "Target: $ISO_DIR/$ISO_NAME"

if ! command -v aria2c &>/dev/null; then
    apt update && apt install -y aria2
fi

aria2c -s 16 -x 16 -k 1M -c -d "$ISO_DIR" -o "$ISO_NAME" "$URL"

echo "=== Download verified and complete! ==="
ls -lh "$ISO_DIR/$ISO_NAME"
