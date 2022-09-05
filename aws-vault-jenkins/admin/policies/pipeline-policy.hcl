path "auth/webapp/role/webapp-role/role-id" {
    capabilities = ["read"]
}

path "auth/webapp/role/webapp-role/secret-id" {
    capabilities = ["create", "update"]
    min_wrapping_ttl = "100s"
    max_wrapping_ttl = "1000s"
}

path "aws/*" {
    capabilities = ["read"]
}

path "db-creds/*" {
    capabilities = ["read"]
}

