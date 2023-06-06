#create an IAM user and an S3 bucket. Then, we will map permissions for that bucket with an IAM policy and attach that policy to the new user

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.42.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
    effect = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.bucket.arn]
    effect = "Allow"
  }
}

resource "aws_iam_user" "new_user" {
  name = "test_user"
}

resource "aws_iam_access_key" "my_access_key" {
  user = aws_iam_user.new_user.name
  pgp_key = var.pgp_key
}

resource "random_pet" "pet_name" {
  length    = 3
  separator = "-"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${random_pet.pet_name.id}-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${random_pet.pet_name.id}-policy"
  description = "My test policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

output "rendered_policy" {
  value = data.aws_iam_policy_document.s3_policy.json
}


output "secret" {
  value = aws_iam_access_key.my_access_key.encrypted_secret
  sensitive = true
}   