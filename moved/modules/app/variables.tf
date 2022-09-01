variable "security_group_ids" {
  type = list(string)
  description = "List of security group ids"
}

variable "public_subnet_id" {
  type = string
  description = "Public subnet id"
}