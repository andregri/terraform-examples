terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.28.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

module "s3_static_website" {
    source = "./modules/aws-s3-static-website-bucket"

    bucket_name = "terraform-test-static-website"

    tags = {
        Terraform = "true"
        Owner     = "Andrea"
    }
}