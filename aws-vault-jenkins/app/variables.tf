variable "aws_region" {
  default = "us-east-1"
}

variable "username" {
  description = "Username of the database"
  type = string
  sensitive = true
}

variable "password" {
  description = "Password of the database"
  type = string
  sensitive = true
}

variable "key_name" {
  description = "SSH key name to log into EC2 instance"
  type = string
}

# URL for Vault OSS binary
variable "vault_zip_file" {
  default = "https://releases.hashicorp.com/vault/1.9.2/vault_1.9.2_linux_amd64.zip"
}

variable "tpl_vault_server_addr" {
  type = string
}