provider "aws" {
  region = "ap-north-1"
}

# S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "medlife-static-site-001"

  tags = {
    Name = "Medlife Website"
  }
}

# Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Public Access Settings
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket Policy (Allow Public Read)
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadAccess",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# Upload Files
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/medlife-master", "**/*")

  bucket = aws_s3_bucket.website_bucket.id
  key    = each.value
  source = "${path.module}/medlife-master/${each.value}"
  etag   = filemd5("${path.module}/medlife-master/${each.value}")
}
