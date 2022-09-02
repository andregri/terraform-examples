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

data "aws_availability_zones" "azs" {
    all_availability_zones = true
}

resource "local_file" "region_json" {
    content  = templatefile("${path.module}/region.json.tftpl", {
        region = data.aws_availability_zones.azs.id,
        azs    = data.aws_availability_zones.azs.names
    })
    filename = "${path.module}/region.json"
}

resource "local_file" "region_yaml" {
    content  = templatefile("${path.module}/region.yaml.tftpl", {
        region = data.aws_availability_zones.azs.id,
        azs    = data.aws_availability_zones.azs.names
    })
    filename = "${path.module}/region.yaml"
}