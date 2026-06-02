output "backend_task_role_arn" {
  description = "ARN of the ECS backend task role"
  value       = aws_iam_role.backend_task_role.arn
}

output "backend_task_execution_role_arn" {
  description = "ARN of the ECS backend task execution role"
  value       = aws_iam_role.backend_task_execution_role.arn
}
