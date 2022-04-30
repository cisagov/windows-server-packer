variable "admin_pass" {
  default     = false
  description = "Windows Administrator Password."
  sensitive   = true
  type        = string
}

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

data "amazon-ami" "commando-vm" {
  filters = {
    name                = "commandovm-base-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["780016325729"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "commando-vm" {
  ami_name                    = "commando-vm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = var.ami_regions
  associate_public_ip_address = true
  communicator                = "winrm"
  encrypt_boot                = true
  instance_type               = "t3.large"
  kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    encrypted             = true
    volume_size           = 250
    volume_type           = "gp2"
    iops                  = 750
  }
  region             = var.build_region
  region_kms_key_ids = var.region_kms_keys
  skip_create_ami    = var.skip_create_ami
  source_ami         = data.amazon-ami.commando-vm.id
  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  tags = {
    Application        = "Commando VM"
    Base_AMI_Name      = data.amazon-ami.commando-vm.name
    GitHub_Release_URL = var.release_url
    OS_Version         = "Windows Server 2022"
    Pre_Release        = var.is_prerelease
    Release            = var.release_tag
    Team               = "VM Fusion - Development"
  }
  temporary_key_pair_type = "ed25519"
  user_data_file          = "src/winrm_bootstrap.txt"
  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  winrm_insecure = true
  winrm_password = var.admin_pass
  winrm_timeout  = "20m"
  winrm_use_ssl  = true
  winrm_username = "Administrator"
}

build {
  sources = [
    "source.amazon-ebs.commando-vm"
  ]
  provisioner "powershell" {
    inline = [
      "cup all",
    ]
  }
}
