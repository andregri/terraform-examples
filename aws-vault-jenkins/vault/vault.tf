provider "vault" {
  # Configuration options
  address           = var.vault_addr
  token             = var.vault_token
  skip_tls_verify   = length(regexall("^http:", var.vault_addr)) > 0
}