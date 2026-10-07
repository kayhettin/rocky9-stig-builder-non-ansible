#!/usr/bin/env bash
set -euo pipefail

ISO_URL="https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-minimal.iso"
MINIMAL_ISO="Rocky-9-latest-x86_64-minimal.iso"[cite: 11]
OUTPUT_ISO="Rocky-9-STIG-Baremetal.iso"[cite: 11]
KS_FILE="http/ks.cfg"
TEMP_KS="/tmp/ks-baremetal.cfg"

if [ ! -f "${MINIMAL_ISO}" ]; then
    echo "Downloading Minimal ISO..."
    wget "${ISO_URL}"[cite: 11]
fi

echo "Adapting Kickstart for baremetal CDROM boot..."
# Replace network URL directive with local cdrom directive for offline deployment
sed 's|url --url=.*|cdrom|g' "${KS_FILE}" > "${TEMP_KS}"[cite: 11]

echo "Fusing Kickstart into ISO..."
sudo mkksiso "${TEMP_KS}" "${MINIMAL_ISO}" "${OUTPUT_ISO}"[cite: 11]

echo "ISO generated: ${OUTPUT_ISO}"
echo "Flash using: sudo dd if=${OUTPUT_ISO} of=/dev/sdX bs=4M status=progress oflag=sync"[cite: 11]
