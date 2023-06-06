#create a group and add an IAM user to the group
#to that IAM user give s3 bucket full access for that created s3 bucket

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

resource "aws_iam_user" "test_user" {
  name = "test_user_1"
}

resource "aws_iam_access_key" "my_access_key" {
  user = aws_iam_user.test_user.name
  pgp_key = var.pgp_key
}

resource "random_pet" "pet_name" {
  length    = 3
  separator = "-"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "${random_pet.pet_name.id}-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
    effect = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.test_bucket.arn]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "test_policy" {
  name        = "${random_pet.pet_name.id}-policy"
  description = "My test policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_group" "test_admin_group" {
  name = "TestAdmin"
}

resource "aws_iam_group_policy_attachment" "custom_policy" {
  group      = aws_iam_group.test_admin_group.name
  policy_arn = aws_iam_policy.test_policy.arn
}

resource "aws_iam_group_membership" "team" {
  name = "tf-testing-group-membership"

  users = [
    aws_iam_user.test_user.name,
  ]

  group = aws_iam_group.test_admin_group.name
}

output "rendered_policy" {
  value = data.aws_iam_policy_document.s3_policy.json
}

output "secret" {
  value = aws_iam_access_key.my_access_key.encrypted_secret
  sensitive = true
} 