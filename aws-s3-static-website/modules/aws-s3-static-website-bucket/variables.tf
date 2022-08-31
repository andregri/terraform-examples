variable "bucket_name" {
  type = string
  description = "Name of the bucket must be unique globally"
}

variable "tags" {
    type = map(string)
    default = {}
}