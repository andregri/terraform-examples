variable "vault_addr" {
    description = "The address of the Vault server, e.g. http://myvault:8200"
    type = string
}

variable "vault_token" {
    description = "The Vault token to setup the instance"
    type = string
    sensitive = true
}

variable "aws_account_id" {
    type = string
    sensitive = true
}