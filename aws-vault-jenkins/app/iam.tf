//--------------------------------------------------------------------
## Vault Agent

resource "aws_iam_instance_profile" "webapp-role" {
  name    = "webapp-role-instance-profile"
  role    = aws_iam_role.webapp.id
}

resource "aws_iam_role" "webapp" {
  name                = "webapp-role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "webapp" {
  name    = "webapp-role-policy"
  role    = aws_iam_role.webapp.id
  policy  = data.aws_iam_policy_document.vault_agent.json
}

data "aws_iam_policy_document" "vault_agent" {
  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}