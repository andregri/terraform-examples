resource "aws_db_instance" "app" {
  allocated_storage    = 5
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = var.username
  password             = var.password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.default.id
  vpc_security_group_ids = [ aws_security_group.allow_postgres.id ]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = module.aws_vpc.public_subnets

  tags = {
    Name = "My DB subnet group"
  }
}