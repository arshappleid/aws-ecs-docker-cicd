variable "tags" {
  type = map(string)
  default = {
    owner   = "Prabhmeet"
    project = "aws-ecs-cicd-docker"
  }
}
