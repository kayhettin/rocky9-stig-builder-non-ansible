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
  iso_checksum     = "file:https://download.rockylinux.org/pub/rocky/9/isos/x86_64/CHECKSUM"
  output_directory = "build-output"
  format           = "qcow2"
  disk_size        = "30000M"
  accelerator      = "kvm"
  http_directory   = "http"
  boot_command     = ["<tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"]
  boot_wait        = "10s"
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "45m"

  qemuargs = [
    ["-m", "2048M"],
    ["-smp", "2"],
    ["-cpu", "host"]
  ]
}

build {
  sources = ["source.qemu.rocky9-stig"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S env {{ .Vars }} bash {{ .Path }}"
    inline = [
      "dnf clean all",
      "rm -rf /etc/ssh/ssh_host_*",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/systemd/random-seed",
      "cloud-init clean --logs"
    ]
  }
}
