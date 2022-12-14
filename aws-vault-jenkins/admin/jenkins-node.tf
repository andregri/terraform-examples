resource "aws_instance" "jenkins-node" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t2.micro"
    subnet_id                   = module.vault_demo_vpc.public_subnets[0]
    key_name                    = var.key_name
    vpc_security_group_ids      = [aws_security_group.jenkins.id]
    associate_public_ip_address = true

    tags = {
      Name     = "${var.environment_name}-jenkins"
    }

    user_data = templatefile("${path.module}/templates/userdata-jenkins.tpl",
    {
      tpl_vault_zip_file          = var.vault_zip_file
      tpl_vault_service_name      = "jenkins-${var.environment_name}"
      tpl_kms_key                 = aws_kms_key.vault.id
      tpl_aws_region              = var.aws_region
      tpl_node_id                 = "${var.environment_name}-jenkins-role"
      vault_server_ip_addr        = aws_instance.vault-server[0].public_ip
    })

    lifecycle {
      ignore_changes = [
        ami,
        tags,
      ]
    }
}