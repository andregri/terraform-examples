output "bucket_name" {
    value = aws_s3_bucket.static_website.id
}

output "bucket_arn" {
    value = aws_s3_bucket.static_website.arn
}

output "bucket_domain" {
    value = aws_s3_bucket_website_configuration.conf.website_domain
}