terraform {
  backend "s3" {
    bucket         = "cisa-cool-terraform-state"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    key            = "windows-server-packer/terraform-post-packer.tfstate"
    profile        = "cool-terraform-backend"
    region         = "us-east-1"
  }
}
