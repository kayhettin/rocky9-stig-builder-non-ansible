# Rocky Linux 9 STIG Image Builder (Non-Ansible)

## Architecture & Objective Overview
This repository provides automated, Infrastructure-as-Code (IaC) pipelines to generate DISA STIG-compliant Rocky Linux 9 machine images. Utilizing HashiCorp Packer, QEMU, and Kickstart files integrated with the OpenSCAP Anaconda add-on, this pipeline bakes the DISA STIG profile directly into the OS at install time. The output is a fully generalized `.qcow2` image for air-gapped Proxmox virtual environments and a custom self-contained ISO for baremetal UEFI deployments.

## Prerequisites
*   **Operating System:** Rocky Linux 9 or RHEL 9 build host.
*   **Packages:** `qemu-kvm`, `libvirt`, `virt-install`, `packer`, `xorriso`, `lorax`, `wget`.
*   **Network:** The build host requires internet access to download upstream minimal ISOs and Packer plugins, but the generated artifacts are designed for offline/air-gapped networks.

## Deployment Instructions

1.  **Configure Environment Variables:**
    Copy `.env.template` to `.env` and populate the `SSH_USERNAME`, `SSH_PASSWORD`, and Proxmox deployment variables. Ensure the password meets strict STIG complexity requirements.
2.  **Prepare the Build Host:**
    Execute `scripts/01-prepare-host.sh` to install QEMU tools and initialize Packer plugins.
3.  **Generate the QEMU Image:**
    Execute `scripts/02-build-qemu-image.sh`. This process takes approximately 45 minutes to compile and remediate the STIG compliance checks.
4.  **Import to Proxmox (Air-Gapped):**
    Transfer the generated `.qcow2` artifact from `build-output/` to your Proxmox host (`/tmp/rocky9-stig`). Execute `scripts/03-import-proxmox.sh` on the Proxmox host to assemble the VM, inject Cloud-Init, and convert it to a template.
5.  **Generate Baremetal ISO (Optional):**
    Execute `scripts/04-build-baremetal-iso.sh` to fuse the Kickstart file into a self-contained Minimal Rocky 9 ISO for physical server deployments using `mkksiso`.

## Directory & File Manifest
*   **`configs/rocky9-stig.pkr.hcl`**: The declarative Packer configuration utilizing the QEMU builder.
*   **`http/ks.cfg`**: The automated Anaconda Kickstart file specifying STIG-mandated logical volume partitions (e.g., `/var/log/audit`, `/tmp`), required security packages, and the OpenSCAP integration.
*   **`scripts/`**: Idempotent Bash scripts abstracting the build, deployment, and ISO generation processes.

## Validation & Smoke Testing
After deploying a VM from the Proxmox template, log in via the console and execute the following commands to validate the engineering baseline:

*   **Verify STIG Application:**
    `oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig --report /root/stig-report.html /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml`
    *Expected Output:* An OpenSCAP compliance scan running and generating an HTML report confirming passed rules.
*   **Verify Cloud-Init Generalization:**
    `systemctl status cloud-init`
    *Expected Output:* Service active and successfully applied user-data networking and SSH keys.
*   **Verify Partitioning:**
    `lsblk -f`
    *Expected Output:* Logical volumes present for `/boot`, `/home`, `/tmp`, `/var`, `/var/log`, and `/var/log/audit`.
*   **Verify `noexec` on `/tmp`:**
    `mount | grep /tmp`
    *Expected Output:* The `/tmp` mount string must explicitly include the `noexec` flag.

## Troubleshooting / Common Pitfalls

*   **Kernel Panic (Attempted to kill init!):**
    QEMU's default `qemu64` virtual CPU lacks the newer instruction sets (like SSE4.2) required by Rocky 9 (x86-64-v2). Ensure the `-cpu host` argument is passed in `qemuargs` to pass through physical CPU capabilities.
*   **Timeout Waiting for SSH:**
    The OpenSCAP remediation script requires significant CPU time post-installation. The Packer `ssh_timeout` must be increased to at least 45 minutes. Additionally, network interfaces may fail to activate; ensure `network --bootproto=dhcp --device=link --activate --onboot=on` is present in `ks.cfg`.
*   **Script Exited with Non-Zero Status (126 / Permission Denied):**
    The STIG profile restricts script execution by mounting `/tmp` with `noexec`. Use `execute_command = "echo '${var.ssh_password}' | sudo -S env {{ .Vars }} bash {{ .Path }}"` to bypass this by reading the script via the bash interpreter directly as root.
*   **Failed Creating QEMU Driver (Executable Not Found):**
    Unlike Fedora, Rocky Linux stores the QEMU binary in `/usr/libexec/qemu-kvm`, which is outside Packer's default `$PATH`. Explicitly declare `qemu_binary = "/usr/libexec/qemu-kvm"` in the Packer source block.
