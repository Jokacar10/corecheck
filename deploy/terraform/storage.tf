resource "aws_s3_bucket" "bitcoin-coverage-data" {
  bucket = "bitcoin-coverage-data-${terraform.workspace}"
}

resource "aws_s3_bucket_ownership_controls" "bitcoin-coverage-data" {
  bucket = aws_s3_bucket.bitcoin-coverage-data.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "bitcoin-coverage-data-public" {
  bucket = aws_s3_bucket.bitcoin-coverage-data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_acl" "bitcoin-coverage-data-public" {
  depends_on = [aws_s3_bucket_public_access_block.bitcoin-coverage-data-public, aws_s3_bucket_ownership_controls.bitcoin-coverage-data]
  bucket     = aws_s3_bucket.bitcoin-coverage-data.id
  acl        = "public-read"
}

resource "aws_s3_bucket_policy" "bitcoin-coverage-data-public" {
  depends_on = [aws_s3_bucket_public_access_block.bitcoin-coverage-data-public, aws_s3_bucket_ownership_controls.bitcoin-coverage-data]
  bucket     = aws_s3_bucket.bitcoin-coverage-data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.bitcoin-coverage-data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "bitcoin-coverage-data" {
  bucket = aws_s3_bucket.bitcoin-coverage-data.id

  rule {
    id     = "bitcoin-coverage-data"
    status = "Enabled"
    expiration {
      days = 180
    }
  }
}

# S3 bucket to store built compute Lambda functions
resource "aws_s3_bucket" "compute_lambdas" {
  bucket   = "corecheck-compute-lambdas-${terraform.workspace}"
  provider = aws.compute_region

  force_destroy = true
}

# enable versioning
resource "aws_s3_bucket_versioning" "corecheck-statemachine-lambdas" {
  bucket   = aws_s3_bucket.compute_lambdas.id
  provider = aws.compute_region
  versioning_configuration {
    status = "Enabled"
  }
}


# remove non current versions after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "corecheck-statemachine-lambdas" {
  bucket   = aws_s3_bucket.compute_lambdas.id
  provider = aws.compute_region

  rule {
    id     = "corecheck-lambdas"
    status = "Enabled"
    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days           = 7
    }
  }
}

# S3 bucket to store built API Gateway Lambda functions
resource "aws_s3_bucket" "api_lambdas" {
  bucket = "corecheck-api-lambdas-${terraform.workspace}"
  force_destroy = true
}

# enable versioning
resource "aws_s3_bucket_versioning" "corecheck-api-lambdas" {
  bucket = aws_s3_bucket.api_lambdas.id
  versioning_configuration {
    status = "Enabled"
  }
}


# remove non current versions after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "corecheck-api-lambdas" {
  bucket = aws_s3_bucket.api_lambdas.id
  rule {
    id     = "corecheck-lambdas"
    status = "Enabled"
    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days           = 7
    }
  }
}
