provider "aws" {
    region = "ap-south-1"
    access_key = "AKIAQNKZUOBOBJLZ6Y56"	
    secret_key = "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"
    default_tags {
    tags = {
      Name     = "SSP"
      Env      = "Dev"
      Project  = "SSP"
      Owner    = "Nikita"}
    }
}

resource "aws_iam_role" "lambda_role" {
    name               = "terraform_aws_lambda_role"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF
}

#IAM Policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


#Policy Attachment on the role

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.iam_policy_for_lambda.arn 
}

# Generates a archive from content, a file or a directory of files. 

data "archive_file" "zip_the_python_code" {
    type        = "zip"
    source_dir  = "${path.module}/python/"
    output_path = "${path.module}/python/lambda-function.zip"
}


#Create a lambda function 
#In terraform ${path.module} is a current directory. 

resource "aws_lambda_function" "terraform_lambda_func" {
    filename = "${path.module}/python/lambda-function.zip"
    function_name = "lambda-from-terraform"
    role = aws_iam_role.lambda_role.arn
    handler = "lambda-function.lambda_handler"
    runtime = "python3.9"
    depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
    source_code_hash = "${filebase64sha256("${path.module}/python/lambda-function.zip")}"
    vpc_config {
    subnet_ids         = ["subnet-089b91a2e5c73c31e", "subnet-04ab559c36347be16"]
    security_group_ids = ["sg-09c5e95bcad44c1eb"]  
  }
    
}

output "terraform_aws_role_output" {
    value = aws_iam_role.lambda_role.name
}

output "terraform_aws_role_arn_output" {
    value = aws_iam_role.lambda_role.arn
}

output "terraform_logging_arn_output" {
    value = aws_iam_policy.iam_policy_for_lambda.arn
}
