provider "aws" {
  # Configuration options
  region = "us-east-1"
}

data "aws_availability_zones" "azs" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.azs.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

moved {
  from = aws_instance.webserver
  to   = module.app.aws_instance.webserver
}

moved {
  from = aws_security_group.allow_http
  to   = module.security_group.aws_security_group.allow_http
}

module "app" {
  source = "./modules/app"

  security_group_ids = [module.security_group.id]
  public_subnet_id   = module.vpc.public_subnets[0]
}

module "security_group" {
  source = "./modules/security"

  vpc_id = module.vpc.vpc_id
}