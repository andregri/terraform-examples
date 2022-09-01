resource "aws_instance" "webserver" {
  ami                         = "ami-05fa00d4c63e32376"
  instance_type               = "t2.micro"
  
  associate_public_ip_address = true
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.public_subnet_id
  
  user_data = <<-EOF
  #!/bin/bash

########################################
##### USE THIS WITH AMAZON LINUX 2 #####
########################################

# get admin privileges
sudo su

# install httpd (Linux 2 version)
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World from $(hostname -f)" > /var/www/html/index.html
  EOF
  
  tags = {
    Name = "webserver"
  }
}