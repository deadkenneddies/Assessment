resource "aws_instance" "ec2_main" {
  provider        = aws.awsmain
  ami             = "<your_ami_id>"
  instance_type   = "<your_instance_type>"
  key_name        = ""
  security_groups = ""
  # Example userdata for the EC2 instance to install necessary software or setup logging
  user_data = <<-EOF
    #!/bin/bash
    # Your EC2 instance setup commands here
    # ...

    # Example code to send logs/metrics to New Relic
    curl -X POST -H 'Content-Type: application/json' \
      -d '{"log": "sample_log_data", "metric": "sample_metric_data"}' \
      https://your-observability-platform-api.com
  EOF
  tags = {
    Name    = "account-main",
    Project = "Assesment",
  }
}

resource "aws_instance" "ec2_account2" {
  provider        = aws.awsaccount2
  ami             = "<your_ami_id>"
  instance_type   = "<your_instance_type>"
  key_name        = ""
  security_groups = ""
    # Example userdata for the EC2 instance to install necessary software or setup logging
  user_data = <<-EOF
    #!/bin/bash
    # Your EC2 instance setup commands here
    # ...

    # Example code to send logs/metrics to New Relic
    curl -X POST -H 'Content-Type: application/json' \
      -d '{"log": "sample_log_data", "metric": "sample_metric_data"}' \
      https://your-observability-platform-api.com
  EOF
  tags = {
    Name    = "account-2",
    Project = "Assesment",
  }
}

##Adding all resourcers with each provider alias from  providers.tf

#Create Bucket
resource "aws_s3_bucket" "telemetry" {
  provider = aws.awsmain
  bucket = "telemetry-bucket-awsmain"
  acl = "private"
}

resource "aws_s3_bucket" "telemetry" {
  provider = aws.awsaccount2
  bucket = "telemetry-bucket-awsaccount2"
  acl = "private"
}

#Adding up to 9 accounts

##Lambdas

resource "aws_lambda_function" "lambda_function" {
  provider = aws.awsmain
  function_name = "<your_lambda_function_name>"
  role          = "<your_lambda_function_role>"
  handler       = "<your_lambda_function_handler>"
  runtime       = "<your_lambda_function_runtime>"
  # ... other Lambda function configuration options

  # Example Lambda function code to process S3 events and send logs/metrics to New Relic
  # (Replace with your actual Lambda code)
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_lambda_function" "lambda_function" {
  provider = aws.awsaccount2
  function_name = "<your_lambda_function_name>"
  role          = "<your_lambda_function_role>"
  handler       = "<your_lambda_function_handler>"
  runtime       = "<your_lambda_function_runtime>"
  # ... other Lambda function configuration options

  # Example Lambda function code to process S3 events and send logs/metrics to New Relic
  # (Replace with your actual Lambda code)
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

#Adding up to 9 accounts


###Lambda to trigger when s3 object is created

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0"

  function_name = "lambda_function"
  description   = "Lambda with trigger with S3 new Object"
  handler       = "<your_lambda_function_handler>"
  runtime       = "<your_lambda_function_runtime>"

  allowed_triggers = {
    AllowExecutionFromS3Bucket = {
      service    = "s3"
      source_arn = module.s3_bucket.s3_bucket_arn
    }
  }

  tags = {
    Pattern = "terraform-s3-lambda"
    Project  = "Assesment"
  }
}

###################
# S3 bucket that will notify and trigger Lambda
###################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = "bucket_notification"
  force_destroy = true

  tags = {
    Pattern = "terraform-s3-lambda"
    Module  = "s3_bucket"
  }
}

module "s3_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "~> 3.0"

  bucket = module.s3_bucket.s3_bucket_id

  eventbridge = true

  lambda_notifications = {
    lambda1 = {
      function_arn  = module.lambda_function.lambda_function_arn
      function_name = module.lambda_function.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "data/"
      filter_suffix = ".json"
    }
  }
}