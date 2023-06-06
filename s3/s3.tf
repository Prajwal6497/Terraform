provider "aws" {
  region = "ap-south-1"  # Replace with your desired region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-tf-bucket"  # Replace with your desired bucket name
  acl    = "private"  # Access control list (ACL) for the bucket
}
