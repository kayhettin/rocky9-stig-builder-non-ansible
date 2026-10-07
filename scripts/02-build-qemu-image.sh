#!/usr/bin/env bash
set -euo pipefail

source .env

echo "Validating Packer template..."
packer validate configs/rocky9-stig.pkr.hcl

echo "Initializing Packer plugins..."
packer init configs/rocky9-stig.pkr.hcl[cite: 9]

echo "Building Rocky 9 STIG QEMU Image..."
packer build configs/rocky9-stig.pkr.hcl[cite: 9]

chmod 600 build-output/*.qcow2
echo "Build complete. Artifact located at build-output/"
