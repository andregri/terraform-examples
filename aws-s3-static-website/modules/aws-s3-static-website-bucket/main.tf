resource "aws_s3_bucket" "static_website" {
    bucket = var.bucket_name

    tags   = var.tags
}

resource "aws_s3_bucket_acl" "public_read" {
    bucket = aws_s3_bucket.static_website.id

    acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "conf" {
    bucket = aws_s3_bucket.static_website.id

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "error.html"
    }
}

resource "aws_s3_bucket_policy" "public_get_object" {
    bucket = aws_s3_bucket.static_website.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "PublicGetReadObjecy"
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = [
                    aws_s3_bucket.static_website.arn,
                    "${aws_s3_bucket.static_website.arn}/*"
                ]
            },
        ]
    })
}