variable "build_region" {
  type    = string
  default = "${env("BUILD_REGION")}"
}

variable "build_region_kms" {
  type    = string
  default = "${env("BUILD_REGION_KMS")}"
}

variable "github_is_prerelease" {
  type    = string
  default = "${env("GITHUB_IS_PRERELEASE")}"
}

variable "github_release_tag" {
  type    = string
  default = "${env("GITHUB_RELEASE_TAG")}"
}

variable "github_release_url" {
  type    = string
  default = "${env("GITHUB_RELEASE_URL")}"
}

variable "skip_create_ami" {
  type    = string
  default = "false"
}

data "amazon-ami" "debian_bullseye" {
  filters = {
    name                = "debian-11-amd64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "example" {
  ami_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  ami_name                    = "example-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = []
  associate_public_ip_address = true
  encrypt_boot                = true
  instance_type               = "t3.small"
  kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  region             = var.build_region
  region_kms_key_ids = {}
  skip_create_ami    = var.skip_create_ami
  source_ami         = "${data.amazon-ami.debian_bullseye.id}"
  ssh_username       = "admin"
  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  tags = {
    Application        = "Example"
    Base_AMI_Name      = "{{ .SourceAMIName }}"
    GitHub_Release_URL = var.github_release_url
    OS_Version         = "Debian Bullseye"
    Pre_Release        = var.github_is_prerelease
    Release            = var.github_release_tag
    Team               = "VM Fusion - Development"
  }
  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
}

build {
  sources = ["source.amazon-ebs.example"]

  provisioner "ansible" {
    playbook_file = "src/upgrade.yml"
  }

  provisioner "ansible" {
    playbook_file = "src/python.yml"
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    playbook_file    = "src/playbook.yml"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }} ; rm -f {{ .Path }}"
    inline          = ["sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force admin"]
    skip_clean      = true
  }

}
