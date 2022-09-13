// KV static secrets

resource "vault_mount" "db_creds" {
  path        = "db-creds"
  type        = "kv"
  options     = { version = "1" }
  description = "KV Version 1 secret engine mount"
}

resource "vault_kv_secret" "secret" {
  path      = "${vault_mount.db_creds.path}/db"
  data_json = jsonencode(
  {
    user     = "jenkins",
    password = "strongpassword"
  }
  )
}

// AWS dynamic secrets

resource "vault_aws_secret_backend" "aws" {
}

resource "vault_aws_secret_backend_role" "pipeline_role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "pipeline-role"
  credential_type = "iam_user"

  policy_document = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PipelineRoleForTerraform",
                "Effect": "Allow",
                "Action": [
                    "ec2:*",
                    "rds:*",
                    "iam:GetInstanceProfile"
                ],
                "Resource": ["*"]
            },
            {
                "Sid": "PassRoleToWebapp",
                "Effect": "Allow",
                "Action": [
                    "iam:PassRole"
                ],
                "Resource": ["arn:aws:iam::${var.aws_account_id}:role/vault-client-role"]
            }
        ]
    }
EOT
}