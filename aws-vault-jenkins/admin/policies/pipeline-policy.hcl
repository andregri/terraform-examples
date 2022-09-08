path "aws/creds/pipeline-role" {
    capabilities = ["read"]
}

path "db-creds/*" {
    capabilities = ["read"]
}

