# Provider

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# Network

data "aws_availability_zones" "available" {} # All AZs in region

resource "aws_vpc" "main" { # Virtual private cloud
  cidr_block = "172.17.0.0/16"
}

resource "aws_subnet" "private" {
  count = var.az_count
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" { # Public subnets
  count = var.az_count
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  vpc_id = aws_vpc.main.id
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" { # Gateway for public subnets
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" { # Route public subnets through gateway
  route_table_id = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_eip" "gw" { # Elatic IP for private subnets
  count = var.az_count
  vpc = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "gw" { # Gateway for private subnets
  count = var.az_count
  subnet_id = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
}

resource "aws_route_table" "private" { # Route internet traffic through gateway for private subnets
  count = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" { # Associate route table for private subnets
  count = var.az_count
  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# Security

resource "aws_security_group" "lb" { # Security group for load balancer
  name = "tf-ecs-alb"
  description = "controls access to the ALB"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" { # Allow access to cluster only for load balancer traffic
  name = "tf-ecs-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    from_port = var.app_port
    to_port = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load balancer

resource "aws_alb" "main" { # Load balancer
  name = "tf-ecs-chat"
  subnets = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" { # Target group
  name = "tf-ecs-chat"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_alb_listener" "front_end" { # All traffic routed to target group
  load_balancer_arn = aws_alb.main.id
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type = "forward"
  }
}

# Containers

resource "aws_ecs_cluster" "main" { # Cluster in which containers are hosted
  name = "tf-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" { # Task defining containers
  family = "app"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.fargate_cpu
  memory = var.fargate_memory

  container_definitions = jsonencode([
    {
      cpu = var.fargate_cpu,
      image = var.app_image,
      memory = var.fargate_memory,
      name = "app",
      networkMode = "awsvpc",
      portMappings = [
        {
          containerPort = var.app_port,
          hostPort = var.app_port
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "main" { # Service to run task(s)
  name = "tf-ecs-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = var.app_count
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name = "app"
    container_port = var.app_port
  }

  depends_on = [
    aws_alb_listener.front_end,
  ]
}
