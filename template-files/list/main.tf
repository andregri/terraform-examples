terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.29.0"
    }

    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

resource "aws_instance" "fleet" {
    count         = 5
    ami           = "ami-05fa00d4c63e32376"
    instance_type = "t2.micro"
}

resource "local_file" "hostname" {
    content  = templatefile("${path.module}/hostname.tftpl",
                            { ec2_instances = aws_instance.fleet[*].public_ip })
    filename = "${path.module}/hostname"
}