module "aws_vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "app-vpc"
    cidr = "10.1.0.0/16"

    azs = ["${var.aws_region}a", "${var.aws_region}b"]
    private_subnets = ["10.1.1.0/24"]
    public_subnets = ["10.1.100.0/24", "10.1.101.0/24"]

    tags = {
        Name = "app-vpc"
    }
}