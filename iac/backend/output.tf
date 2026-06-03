output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.dns_name
}

output "prod_ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.prod_ecs.cluster_name
}

output "stage_ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.stage_ecs.cluster_name
}


output "dev_ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.dev_ecs.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}