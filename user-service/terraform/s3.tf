resource "aws_s3_bucket" "avatars_bucket" {
  bucket = "users-avatar-banco-cerdos-2026-mau"
}
resource "aws_s3_bucket_public_access_block" "avatars_public" {
  bucket = aws_s3_bucket.avatars_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "avatars_policy" {
  bucket = aws_s3_bucket.avatars_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.avatars_public]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.avatars_bucket.arn}/*"
      }
    ]
  })
}