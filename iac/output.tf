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
