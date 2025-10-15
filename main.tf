provider "aws" {
  region = "us-east-1"
}

# Lambda Function
resource "aws_lambda_function" "ec2_scheduler" {
  filename         = "lambda/ec2_scheduler.zip"
  function_name    = "ec2_scheduler"
  handler          = "ec2_scheduler.lambda_handler"
  runtime          = "python3.9"

  role             = "arn:aws:iam::379196425754:role/LambdaInstanceSchedulerRole"
  source_code_hash = filebase64sha256("lambda/ec2_scheduler.zip")
}

# Scheduler IAM Role
resource "aws_iam_role" "scheduler_role" {
  name = "scheduler-invoke-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "scheduler.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Scheduler IAM Policy (allow invoking Lambda)
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "scheduler-invoke-lambda-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = aws_lambda_function.ec2_scheduler.arn
      }
    ]
  })
}

# Start EC2 at 5:05 PM IST (11:35 UTC)
resource "aws_scheduler_schedule" "start_ec2" {
  name                = "start-ec2-schedule"
  schedule_expression = "cron(35 11 ? * * *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.ec2_scheduler.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({
      action       = "start",
      instance_ids = ["i-0f3c373e89cf2211f"]
    })
  }

  depends_on = [aws_lambda_function.ec2_scheduler]
}

# Stop EC2 at 5:10 PM IST (11:40 UTC)
resource "aws_scheduler_schedule" "stop_ec2" {
  name                = "stop-ec2-schedule"
  schedule_expression = "cron(40 11 ? * * *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.ec2_scheduler.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({
      action       = "stop",
      instance_ids = ["i-0f3c373e89cf2211f"]
    })
  }

  depends_on = [aws_lambda_function.ec2_scheduler]
}