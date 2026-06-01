variable "tags" {
  type = map(string)
  default = {
    owner   = "Prabhmeet"
    project = "prab-cicd-ecs"
  }
}

variable "project_name" {
  type = string
  default = "prab-cicd-ecs"
}