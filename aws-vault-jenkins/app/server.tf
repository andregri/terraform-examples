resource "aws_instance" "web_server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name = var.key_name

    associate_public_ip_address = true
    subnet_id = module.aws_vpc.public_subnets[0]
    iam_instance_profile = data.aws_iam_instance_profile.vault-client.id

    security_groups = [
      aws_security_group.allow_http.id,
      aws_security_group.allow_ssh.id  
    ]

    user_data = templatefile("${path.module}/templates/userdata-vaultagent.tpl",
    {
      tpl_vault_zip_file          = var.vault_zip_file
      tpl_vault_service_name      = "webapp"
      tpl_aws_region              = var.aws_region
      tpl_node_id                 = "webapp-role"
      tpl_vault_server_addr       = var.tpl_vault_server_addr
    })

    lifecycle {
      ignore_changes = [
        ami,
        tags
      ]
    }
}