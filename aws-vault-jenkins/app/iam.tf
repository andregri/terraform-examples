//--------------------------------------------------------------------
## Vault Agent

data "aws_iam_instance_profile" "vault-client" {
  name = "vault-client-instance-profile"
}
