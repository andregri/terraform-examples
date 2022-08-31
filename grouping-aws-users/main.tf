terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  groups = {
    "dev" = ["andrea", "john", "paul"],
    "ops" = ["lisa", "alice", "andrea"],
    "qa"  = ["bob", "paul"],
    "sec" = ["alice", "bob"]
  }

  users = flatten([for group, users in local.groups : users])

  users_map = [
    for user in toset(local.users) : [
        for group_name, users in local.groups : { "${user}" = group_name } if contains(users, user)
    ]
  ]

  roles_by_user = {
    for user in toset(local.users) : user => [
        for group in keys(local.groups) : group if contains(local.groups[group], user)
    ]
  }

  /*users_by_role = {
    for user, roles in local.roles_by_user : role => user...
  }*/

  groupssss = [for k, v in aws_iam_group.group : v["name"]]

  roles_by_user_2 = transpose(local.groups)
}

resource "aws_iam_group" "group" {
  for_each = local.groups
  name     = each.key
}

resource "aws_iam_user" "user" {
  for_each = toset(local.users)
  name     = each.key
}

resource "aws_iam_group_membership" "group-membership" {
  for_each = local.groups

  name = "${each.key}-membership"

  users = [ for u in each.value : aws_iam_user.user[u].name ]
  group = aws_iam_group.group[each.key].name
}