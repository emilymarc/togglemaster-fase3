terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket       = "togglemaster-tfstate-25783" # your bucket
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native locking
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}