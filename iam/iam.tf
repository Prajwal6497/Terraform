#Create an IAM User and give Console Access

provider "aws" {
  region = "ap-south-1" 
}

resource "aws_iam_user" "example_user" {
  name = "test-user"
}

resource "aws_iam_user_login_profile" "example_login_profile" {
  user                    = aws_iam_user.example_user.name
  password_reset_required = true
  password_length         = 8 
  password                = "more123$"
}

output "username" {
  value = aws_iam_user.example_user.name
}

output "login_link" {
  value = "https://174241535978.signin.aws.amazon.com/console" 
}

