# This effectively makes response wrapping mandatory for this path by setting min_wrapping_ttl to 1 second.
# This also sets this path's wrapped response maximum allowed TTL to 90 seconds.
path "auth/approle/role/jenkins-role/secret-id" {
    capabilities = ["create", "update"]
    min_wrapping_ttl = "100s"
    max_wrapping_ttl = "300s"
}

