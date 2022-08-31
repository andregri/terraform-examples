output "bucket_name" {
    value = module.s3_static_website.bucket_name
    description = "Name (id) of the bucket"
}

output "bucket_arn" {
    value = module.s3_static_website.bucket_arn
    description = "ARN of the bucket"
}

output "bucket_domain" {
    value = "http://${module.s3_static_website.bucket_name}.${module.s3_static_website.bucket_domain}"
    description = "Domain name of the bucket"
}