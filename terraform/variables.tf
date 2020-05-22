variable "aws_region" {
  description = "The AWS region"
  default = "ca-central-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  default = "default"
}

variable "az_count" {
  description = "Number of AZs to deploy to within region"
  default = 2
}

variable "app_image" {
  description = "Docker image referenced by task definition"
  default = "ashtonmeuser/dockerized-express:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image"
  default = 3000
}

variable "app_count" {
  description = "Number of docker containers to run"
  default = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units (CPU units)"
  default = 256
}

variable "fargate_memory" {
  description = "Fargate instance memory (MB)"
  default = 512
}
