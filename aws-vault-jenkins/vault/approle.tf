// Jenkins

resource "vault_auth_backend" "jenkins" {
  type = "approle"
  path = "jenkins"
}

data "vault_policy_document" "jenkins" {
  rule {
    path                = "auth/pipeline/role/pipeline-role/secret-id"
    capabilities        = ["create", "update"]
    min_wrapping_ttl    = "100s"
    max_wrapping_ttl    = "300s"
  }

  rule {
    path                = "auth/pipeline/role/pipeline-role/role-id"
    capabilities        = ["read"]
  }
}

resource "vault_policy" "jenkins" {
  name   = "jenkins-policy"
  policy = data.vault_policy_document.jenkins.hcl
}

resource "vault_approle_auth_backend_role" "jenkins" {
  backend               = vault_auth_backend.jenkins.path
  role_name             = "jenkins-role"
  token_policies        = ["default", vault_policy.jenkins.name]

  secret_id_num_uses    = 0
  secret_id_ttl         = 1800

  token_max_ttl         = 1800
  token_num_uses        = 10
}

// Pipeline
resource "vault_auth_backend" "pipeline" {
  type = "approle"
  path = "pipeline"
}

data "vault_policy_document" "pipeline" {
  rule {
    path                = "aws/creds/pipeline-role"
    capabilities        = ["read"]
  }

  rule {
    path                = "db-creds/*"
    capabilities        = ["read"]
  }
}

resource "vault_policy" "pipeline" {
  name   = "pipeline-policy"
  policy = data.vault_policy_document.pipeline.hcl
}

resource "vault_approle_auth_backend_role" "pipeline" {
  backend               = vault_auth_backend.pipeline.path
  role_name             = "pipeline-role"
  token_policies        = ["default", vault_policy.pipeline.name]

  secret_id_num_uses    = 1
  secret_id_ttl         = 300

  token_max_ttl         = 1800
  token_num_uses        = 3
}