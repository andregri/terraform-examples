resource "aws_instance" "web_server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name = var.key_name

    associate_public_ip_address = true
    subnet_id = module.aws_vpc.public_subnets[0]

    security_groups = [
      aws_security_group.allow_http.id,
      aws_security_group.allow_ssh.id  
    ]

    user_data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y apache2
        echo "Hello World" > /var/www/html/index.html
        systemctl restart apache2
        sudo apt install -y postgresql postgresql-contrib
        sudo apt install -y postgresql-client-common
    EOF

    lifecycle {
      ignore_changes = [
        ami,
        tags
      ]
    }
}