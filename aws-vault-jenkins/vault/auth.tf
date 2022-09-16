resource "vault_auth_backend" "aws" {
  type = "aws"
  path = "aws"
}

resource "vault_aws_auth_backend_client" "aws" {
  backend    = vault_auth_backend.aws.path
}

resource "vault_aws_auth_backend_role" "example" {
  backend                         = vault_auth_backend.aws.path
  role                            = "webapp-role"
  auth_type                       = "iam"
  bound_iam_principal_arns        = ["arn:aws:iam::${var.aws_account_id}:role/vault-client-role"]
  token_policies                  = ["default", vault_policy.webapp.name]

  depends_on                      = [vault_aws_auth_backend_client.aws]
}

data "vault_policy_document" "webapp" {
  rule {
    path                = "db-creds/*"
    capabilities        = ["read"]
  }
}

resource "vault_policy" "webapp" {
  name   = "webapp-policy"
  policy = data.vault_policy_document.webapp.hcl
}