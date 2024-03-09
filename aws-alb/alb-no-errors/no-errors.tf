resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "us_east_1a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "us_east_1b" {
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "http" {
  name   = "sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "noerrors" {
  ami             = "ami-0f403e3180720dd7e" # amazon linux 2023 us-east-1
  instance_type   = "t3.micro"
  subnet_id       = aws_default_subnet.us_east_1a.id
  security_groups = [aws_security_group.http.id]

  tags = {
    Name = "No errors"
  }

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install httpd -y
echo "<html><body>Hello from $(hostname)</body></html>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
}

resource "aws_lb_target_group" "noerrors" {
  name     = "no-errors-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    enabled  = true
    path     = "/index.html"
    port     = 80
    protocol = "HTTP"
  }

}

resource "aws_lb" "noerrors" {
  name               = "no-errors-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http.id]
  subnets            = [aws_default_subnet.us_east_1a.id, aws_default_subnet.us_east_1b.id]

  tags = {
    Environment = "No errors"
  }
}

resource "aws_lb_target_group_attachment" "noerrors" {
  target_group_arn = aws_lb_target_group.noerrors.arn
  target_id        = aws_instance.noerrors.id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.noerrors.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.noerrors.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.noerrors.dns_name
}