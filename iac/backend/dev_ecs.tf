module "dev_ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.project_name}-dev"
  cloudwatch_log_group_class             = var.logs_retention_config.class
  cloudwatch_log_group_retention_in_days = var.logs_retention_config.retention_in_days

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/${var.tags.Application}-ecs-cluster/logs"
      }
    }
  }

  # Cluster capacity providers
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100 - var.cluster_config.spot_instance_percentage
      base   = 2 ## Since we have 2 services
    }
    FARGATE_SPOT = {
      weight = var.cluster_config.spot_instance_percentage
    }
  }
  ## Services 
  services = {
	/*
    frontend = {
      cpu                                    = var.service_1_config.service_cpu_allocation
      memory                                 = var.service_1_config.service_memory_allocation
      desired_count                          = var.service_1_config.desired_count
      cloudwatch_log_group_class             = var.logs_retention_config.class
      cloudwatch_log_group_retention_in_days = var.logs_retention_config.retention_in_days
      # Container definition(s)
      container_definitions = {
        frontend = {
          cpu       = var.service_1_config.task_cpu_allocation
          memory    = var.service_1_config.task_memory_allocation
          essential = true
          image     = var.service_1_config.image
          portMappings = [
            {
              name          = var.service_1_config.port_name
              containerPort = var.service_1_config.container_port
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonlyRootFilesystem = false

          enable_cloudwatch_logging = true
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/aws/ecs/${var.tags.Application}-${var.service_1_config.name}"
              "awslogs-region"        = "us-east-1"
              "awslogs-stream-prefix" = "ecs-${var.service_1_config.name}"
            }
          }
          memoryReservation = 100
        }
      }

      service_connect_configuration = {
        namespace = aws_service_discovery_http_namespace.frontend.arn
        service = [{
          client_alias = {
            port     = var.service_1_config.container_port
            dns_name = "${var.service_1_config.name}"

            #discovery_name = "${var.service_1_config.name}-v1" - optional
        }, port_name = var.service_1_config.port_name }]
      }
      ## Need to configure Load Balancer for frontend service
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups[var.service_1_config.name].arn
          container_name   = var.service_1_config.name
          container_port   = var.service_1_config.container_port
        }
      }

      subnet_ids = [module.vpc.private_subnets[0]]

      #Only allow traffic from ALB to ECS Service
      security_group_ids = [aws_security_group.frontend_ecs.id]

      security_group_egress_rules = {
        all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    },
	*/
    ## Backend Service
    backend = {
      family                                 = var.service_1_config.family_dev
      runtime_platform = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }
      cpu                                    = var.service_1_config.service_cpu_allocation
      memory                                 = var.service_1_config.service_memory_allocation
      desired_count                          = var.service_1_config.desired_count
      cloudwatch_log_group_class             = var.logs_retention_config.class
      cloudwatch_log_group_retention_in_days = var.logs_retention_config.retention_in_days
      # Container definition(s)
      container_definitions = {
        flask-api = {
          cpu       = var.service_1_config.task_cpu_allocation
          memory    = var.service_1_config.task_memory_allocation
          essential = true
          image     = var.service_1_config.image
          portMappings = [
            {
              name          = var.service_1_config.port_name
              containerPort = var.service_1_config.container_port
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonlyRootFilesystem = false

          enable_cloudwatch_logging   = true
          create_cloudwatch_log_group = false
          log_configuration = {
            log_driver = "awslogs"
            options = {
              "awslogs-group"         = "/aws/ecs/backend/backend"
              "awslogs-region"        = "us-east-1"
              "awslogs-stream-prefix" = "ecs-backend-dev"
            }
          }
          memoryReservation = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["backend-dev-tg"].arn
          container_name   = var.service_1_config.container_name
          container_port   = var.service_1_config.container_port
        }
      }

      subnet_ids = [module.vpc.private_subnets[0]]

      #Only allow traffic from ALB to ECS Service
      security_group_ids = [aws_security_group.backend_ecs.id]

      security_group_egress_rules = {
        all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
  }

  tags = var.tags
}
