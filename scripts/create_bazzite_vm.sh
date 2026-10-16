#!/bin/bash
# create_bazzite_vm.sh - Creates Proxmox KVM VM 100 for Bazzite Gaming Console with PCIe GPU Passthrough
set -e

VMID=100
NAME="Bazzite-LivingRoom"
STORAGE="hdd-storage"
ISO="bazzite-deck-nvidia-stable-amd64.iso"

echo "=== Creating Bazzite Living Room Console VM ($VMID) ==="

# Check if VM already exists
if qm status "$VMID" &>/dev/null; then
    echo "VM $VMID already exists. Configuration:"
    qm config "$VMID"
    exit 0
fi

qm create "$VMID" \
  --name "$NAME" \
  --machine q35 \
  --bios ovmf \
  --efidisk0 "${STORAGE}:0,efitype=4m,pre-enrolled-keys=0" \
  --scsihw virtio-scsi-single \
  --scsi0 "${STORAGE}:64,discard=on,ssd=1" \
  --cpu host,hidden=1 \
  --cores 6 \
  --sockets 1 \
  --memory 8192 \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --hostpci0 0000:26:00,pcie=1,x-vga=1 \
  --ide2 "${STORAGE}:iso/${ISO},media=cdrom" \
  --boot order=ide2\;scsi0 \
  --onboot 1

echo "=== VM $VMID created successfully! ==="
qm config "$VMID"
