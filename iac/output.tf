output "vpc_id" {
  description = "VPC created by the backend module"
  value       = module.backend.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name from the backend module"
  value       = module.backend.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name from the backend module"
  value       = module.backend.ecs_cluster_name
}

output "backend_task_role_arn" {
  description = "ARN of the ECS backend task role"
  value       = module.iam.backend_task_role_arn
}

output "backend_task_execution_role_arn" {
  description = "ARN of the ECS backend task execution role"
  value       = module.iam.backend_task_execution_role_arn
}
