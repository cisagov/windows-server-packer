variable "ami_regions" {
  default     = []
  description = "The list of AWS regions to copy the AMI to once it has been created. Example: [\"us-east-1\"]"
  type        = list(string)
}

variable "build_region" {
  default     = "us-east-1"
  description = "The region in which to retrieve the base AMI from and build the new AMI."
  type        = string
}

variable "build_region_kms" {
  default     = "alias/cool-amis"
  description = "The ID or ARN of the KMS key to use for AMI encryption."
  type        = string
}

variable "is_prerelease" {
  default     = false
  description = "The pre-release status to use for the tags applied to the created AMI."
  type        = bool
}

variable "region_kms_keys" {
  default     = {}
  description = "A map of regions to copy the created AMI to and the KMS keys to use for encryption in that region. The keys for this map must match the values provided to the aws_regions variable. Example: {\"us-east-1\": \"alias/example-kms\"}"
  type        = map(string)
}

variable "release_tag" {
  default     = ""
  description = "The GitHub release tag to use for the tags applied to the created AMI."
  type        = string
}

variable "release_url" {
  default     = ""
  description = "The GitHub release URL to use for the tags applied to the created AMI."
  type        = string
}

variable "skip_create_ami" {
  default     = false
  description = "Indicate if Packer should not create the AMI."
  type        = bool
}

data "amazon-ami" "windows" {
  filters = {
    name                = "Windows_Server-2022-English-Full-Base-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "windows" {
  ami_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  ami_name                    = "windows-commando-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = var.ami_regions
  associate_public_ip_address = true
  encrypt_boot                = false
  instance_type               = "t2.large"
  // kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  region = var.build_region
  // region_kms_key_ids = var.region_kms_keys
  skip_create_ami = var.skip_create_ami
  source_ami      = data.amazon-ami.windows.id

  communicator   = "winrm"
  user_data_file = "src/winrm_bootstrap.txt"
  winrm_username = "Administrator"
  winrm_timeout  = "20m"
  winrm_use_ssl  = true
  winrm_insecure = true

  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }

  tags = {
    Application        = "Windows Commando VM"
    Base_AMI_Name      = data.amazon-ami.windows.name
    GitHub_Release_URL = var.release_url
    OS_Version         = "Windows Server 2022"
    Pre_Release        = var.is_prerelease
    Release            = var.release_tag
    Team               = "VM Fusion - Development"
  }

  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
}

build {
  sources = [
    "source.amazon-ebs.windows"
  ]

  provisioner "powershell" {
    inline = [
      "write-output Remove Windows Defender",
      "Uninstall-WindowsFeature Windows-Defender",
    ]
  }

  provisioner "windows-restart" {}
}
