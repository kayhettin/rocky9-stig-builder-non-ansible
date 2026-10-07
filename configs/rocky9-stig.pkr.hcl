packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "ssh_username" {
  type    = string
  default = "${env("SSH_USERNAME")}"
}

variable "ssh_password" {
  type      = string
  default   = "${env("SSH_PASSWORD")}"
  sensitive = true
}

source "qemu" "rocky9-stig" {
  qemu_binary      = "/usr/libexec/qemu-kvm"
  iso_url          = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso"
  iso_checksum     = "file:https://download.rockylinux.org/pub/rocky/9/isos/x86_64/CHECKSUM"[cite: 9]
  output_directory = "build-output"[cite: 9]
  format           = "qcow2"[cite: 9]
  disk_size        = "30000M"[cite: 9]
  accelerator      = "kvm"[cite: 9]
  http_directory   = "http"[cite: 9]
  boot_command     = ["<tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"][cite: 9]
  boot_wait        = "10s"[cite: 9]
  ssh_username     = var.ssh_username[cite: 9]
  ssh_password     = var.ssh_password[cite: 9]
  ssh_timeout      = "45m"[cite: 9]

  qemuargs = [
    ["-m", "2048M"],[cite: 9]
    ["-smp", "2"],[cite: 9]
    ["-cpu", "host"][cite: 9]
  ]
}

build {
  sources = ["source.qemu.rocky9-stig"][cite: 9]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S env {{ .Vars }} bash {{ .Path }}"[cite: 9]
    inline = [
      "dnf clean all",[cite: 9]
      "rm -rf /etc/ssh/ssh_host_*",[cite: 9]
      "truncate -s 0 /etc/machine-id",[cite: 9]
      "rm -f /var/lib/systemd/random-seed",[cite: 9]
      "cloud-init clean --logs"[cite: 9]
    ]
  }
}
