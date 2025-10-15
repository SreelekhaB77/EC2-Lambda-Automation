output "lambda_name" {
  value = aws_lambda_function.ec2_scheduler.function_name
}

output "start_schedule_arn" {
  value = aws_scheduler_schedule.start_ec2.arn
}

output "stop_schedule_arn" {
  value = aws_scheduler_schedule.stop_ec2.arn
}

