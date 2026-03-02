terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use the profile we just set up
provider "aws" {
  region  = "ca-central-1"
  profile = "terraform-profile"
}

# Fetches your Account ID and ARN
data "aws_caller_identity" "current" {}

# Fetches your default VPC info
data "aws_vpc" "default" {
  default = true
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
