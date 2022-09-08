//--------------------------------------------------------------------
// Resources

## Vault Server IAM Config
resource "aws_iam_instance_profile" "vault-server" {
  name = "${var.environment_name}-vault-server-instance-profile"
  role = aws_iam_role.vault-server.name
}

resource "aws_iam_role" "vault-server" {
  name               = "${var.environment_name}-vault-server-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-server" {
  name   = "${var.environment_name}-vault-server-role-policy"
  role   = aws_iam_role.vault-server.id
  policy = data.aws_iam_policy_document.vault-server.json
}

## Vault Client IAM Config
resource "aws_iam_role" "vault-client" {
  name                = "vault-client-role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-client" {
  name    = "vault-client-role-policy"
  role    = aws_iam_role.vault-client.id
  policy  = data.aws_iam_policy_document.vault-client.json
}

resource "aws_iam_instance_profile" "vault-client" {
  name = "vault-client-instance-profile"
  role = aws_iam_role.vault-client.id
}

//--------------------------------------------------------------------
// Data Sources

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

data "aws_iam_policy_document" "vault-server" {
  statement {
    sid    = "RaftSingle"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }

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

  statement {
    sid    = "VaultAWSDynamicSecret"
    effect = "Allow"
    actions = [
      "iam:AttachUserPolicy",
      "iam:CreateAccessKey",
      "iam:CreateUser",
      "iam:DeleteAccessKey",
      "iam:DeleteUser",
      "iam:DeleteUserPolicy",
      "iam:DetachUserPolicy",
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
      "iam:ListUserPolicies",
      "iam:PutUserPolicy",
      "iam:AddUserToGroup",
      "iam:RemoveUserFromGroup",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/vault-*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }
}

# This role is needed just to identify clients running the vault agent.
# Add a useless permission because you can't create a role with no one.
data "aws_iam_policy_document" "vault-client" {
  statement {
    sid = "VaultAgent"
    effect = "Allow"
    actions = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}