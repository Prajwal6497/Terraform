data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::197857026523:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["65d3595c-c730-4a11-5e37-5115bae05e5e"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = "AzureSentinelRole"
  description           = "Azure Sentinel Integration"
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
}


resource "aws_sqs_queue" "sqs_queue" {
  name                      = var.trailQueueName
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  kms_master_key_id         = aws_kms_key.primary.arn

  depends_on = [
    aws_s3_bucket.cloudtrailbucket,
    aws_kms_key.primary
  ]
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "CloudTrailSQS",
      "Effect": "Allow",
      "Principal": {
          "Service": "s3.amazonaws.com"
      },
      "Action": [
          "SQS:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.sqs_queue.arn}",
      "Condition": {
          "ArnLike": {
              "aws:SourceArn": "${aws_s3_bucket.cloudtrailbucket.arn}"
          },
          "StringEquals": {
              "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
      }
    },
    {
      "Sid": "CloudTrailSQS",
      "Effect": "Allow",
      "Principal": {
           "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AzureSentinelRole"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage",
        "SQS:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.sqs_queue.arn}" 
    }
  ]
}
POLICY
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.cloudtrailbucket.id
  queue {
    id        = "${var.trailName}-log-event"
    queue_arn = aws_sqs_queue.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_sqs_queue.sqs_queue
  ]
}
output "sentinelrole" {
    value = aws_iam_role.this.arn
}

output "sqsurl" {
  value = aws_sqs_queue.sqs_queue.url
}

