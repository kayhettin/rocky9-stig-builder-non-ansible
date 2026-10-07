#!/usr/bin/env bash
set -euo pipefail

source .env

IMAGE_PATH="/tmp/rocky9-stig"
VM_ID="${VM_ID:-9000}"
VM_NAME="${VM_NAME:-Rocky-9-STIG-Template}"
STORAGE_POOL="${STORAGE_POOL:-local-lvm}"

if ! command -v qm &> /dev/null; then
    echo "Error: 'qm' command not found. This script must be run on a Proxmox node."
    exit 1
fi

if qm status "${VM_ID}" &> /dev/null; then
    echo "Warning: VM ${VM_ID} already exists. Destroying to maintain idempotency..."
    qm stop "${VM_ID}" || true
    qm destroy "${VM_ID}"
fi

echo "Creating empty VM..."
qm create "${VM_ID}" --name "${VM_NAME}" --memory 2048 --net0 virtio,bridge=vmbr0

echo "Importing disk..."
qm importdisk "${VM_ID}" "${IMAGE_PATH}" "${STORAGE_POOL}"

echo "Configuring hardware and Cloud-Init..."
qm set "${VM_ID}" --scsihw virtio-scsi-pci --scsi0 "${STORAGE_POOL}:vm-${VM_ID}-disk-0"
qm set "${VM_ID}" --ide2 "${STORAGE_POOL}:cloudinit"
qm set "${VM_ID}" --boot c --bootdisk scsi0

echo "Converting to template..."
qm template "${VM_ID}"
