path "auth/pipeline/role/pipeline-role/secret-id" {
    capabilities = ["create", "update"]
    min_wrapping_ttl = "100s"
    max_wrapping_ttl = "300s"
}

