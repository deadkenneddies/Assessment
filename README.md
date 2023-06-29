# **Technical Assessment**

## **Scenario I**

## Code for Scenario I

The first thing to define is how to deploy in a multi AWS environment. For this step and as a quick solution, I define multiple providers with alias for aws:

```python
provider "aws" {
    alias = "awsmain"
    region = "us-east-1"
    profile = "account1"
}

provider "aws" {
    alias = "awsaccount2"
    region = "us-east-1"
    profile = "account2"
}

provider "aws" {
    alias = "awsaccount3"
    region = "us-east-1"
    profile = "account3"
}

###### Adding provider up to 9 different accounts
```

This provider alias, will be a declared profile in our aws cli with the aws key necessary to connect to the account. For a future improvement we can change this to assume roles or use terraform workspaces.

```python
resource "aws_instance" "ec2_account2" {
  provider        = aws.awsaccount2
  ami             = "<your_ami_id>"
  instance_type   = "<your_instance_type>"
  key_name        = ""
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
    Name    = "account-main",
    Project = "Assessment",
  }
}

##Adding all resources with each provider alias from  providers.tf

```

Creating S3 Buckets. For future improvement we can add versioning and encryption to the bucket.

```python
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
```
Adding Lambda
```python

##Lambdas

resource "aws_lambda_function" "lambda_function" {
  provider = aws.awsmain
  function_name = "<your_lambda_function_name>"
  role          = "<your_lambda_function_role>"
  handler       = "<your_lambda_function_handler>"
  runtime       = "<your_lambda_function_runtime>"
  # ... other Lambda function configuration options

  # Example Lambda function code to process S3 events and send logs/metrics to New Relic
  # (Replace with your actual Lambda code)
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_lambda_function" "lambda_function" {
  provider = aws.awsaccount2
  function_name = "<your_lambda_function_name>"
  role          = "<your_lambda_function_role>"
  handler       = "<your_lambda_function_handler>"
  runtime       = "<your_lambda_function_runtime>"
  # ... other Lambda function configuration options

  # Example Lambda function code to process S3 events and send logs/metrics to New Relic
  # (Replace with your actual Lambda code)
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

#Adding up to 9 accounts
```

For the additional part to trigger the lambda when an object is created, I added 2 modules and use 

```python
  allowed_triggers = {
    AllowExecutionFromS3Bucket = {
      service    = "s3"
      source_arn = module.s3_bucket.s3_bucket_arn
    }
  }
```

And S3 Notification

```python
###################
# S3 bucket that will notify and trigger Lambda
###################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = "bucket_notification"
  force_destroy = true

  tags = {
    Pattern = "terraform-s3-lambda"
    Module  = "s3_bucket"
  }
}

module "s3_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "~> 3.0"

  bucket = module.s3_bucket.s3_bucket_id

  eventbridge = true

  lambda_notifications = {
    lambda1 = {
      function_arn  = module.lambda_function.lambda_function_arn
      function_name = module.lambda_function.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "data/"
      filter_suffix = ".json"
    }
  }
}
```

This will subscrime an s3 notification with an eventbridge pattern of 
```python
"s3:ObjectCreated:*"
```
And will trigger our Lambda


### Things to have in mind to improve our architecture



<ol>
<li>Centralize logging and metrics collection: Instead of configuring each EC2 instance to send logs and metrics individually, you can explore services like AWS CloudWatch Logs and CloudWatch Metrics, which provide centralized logging and monitoring capabilities. This can simplify your setup and reduce management overhead.</li>

<li>Utilize AWS CloudTrail: Enable AWS CloudTrail to capture API activity across your AWS accounts. CloudTrail provides valuable audit logs that can be integrated with your observability platform for better visibility into account-wide activities.</li>

<li>Efficient Setup for Multiple AWS Accounts: To define Workspaces like with terraform Cloud</li>

<li>Use AWS Secrets Manager: If your Lambda function requires sensitive information like API keys or access tokens, store them securely in AWS Secrets Manager. This ensures secure and centralized management of secrets across multiple accounts.</li>
</ol>


## **Scenario II**

First of all we have to define our Uptime Metric.

We should first generate data to analyse, collecting logs and tracing applications.
Interview stakeholders will help us to define a KPI that goes with the business and product
Define SLIs and SLOs to have in mind for thresholds
Generate Alerts and keep tweaking them

A good approach could be:
<ol>
<li>Define the scope: Identify the list of services and applications that you want to measure the uptime for. This includes both internally developed applications and third-party services.</li>

<li>Determine the availability criteria: Decide on the criteria that define uptime for each service. This could be based on factors like response time, availability percentage, or specific health checks.</li>

<li> Establish monitoring and alerting: Implement a monitoring solution that periodically checks the availability of each service. You can use tools like AWS CloudWatch, New Relic Synthetics, or third-party monitoring platforms. Set up appropriate alerts to notify the operations team or relevant stakeholders in case of service disruptions or downtime.</li>

<li>  Define service-level objectives (SLOs): Establish SLOs for each service/application, specifying the desired uptime percentage. For example, you might set a goal of 99.9% uptime for a critical application.</li>

<li> Collect availability data: Continuously collect data on service availability. This could be done through monitoring tools, log analysis, or by integrating with the relevant APIs provided by the services themselves.</li>

<li>  Calculate uptime: Analyze the collected data to calculate the uptime of each service/application. This can be done by measuring the actual uptime percentage over a given period compared to the SLOs defined.</li>

<li> Visualize and report uptime metrics: Use dashboards or reporting tools to present uptime metrics in a clear and understandable manner. This enables C-level executives and stakeholders to track the overall uptime performance of your services.</li>

<li>  Identify and address downtime causes: In case of service disruptions or downtime, investigate the root causes and take appropriate actions to mitigate them. This may involve identifying and resolving issues in your applications, infrastructure, or third-party services/tools.</li>
</ol>