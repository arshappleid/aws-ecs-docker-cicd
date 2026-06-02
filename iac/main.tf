
module "backend" {
  source = "./backend"

  project_name = var.project_name

  tags = merge(var.tags, {
    module = "backend"
  })
}

module "iam" {
  source = "./iam"

  project_name = var.project_name

  tags = merge(var.tags, {
    module = "iam"
  })
}

