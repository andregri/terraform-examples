variable "aws_region" {
  default = "us-east-1"
}

variable "username" {
  description = "Username of the database"
  type = string
  sensitive = true
}

variable "password" {
  description = "Password of the database"
  type = string
  sensitive = true
}

variable "key_name" {
  description = "SSH key name to log into EC2 instance"
  type = string
}