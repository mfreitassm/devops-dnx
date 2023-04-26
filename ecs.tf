
resource "aws_ecs_cluster" "laravel-ecs-cluster" {
  name = "laravel-ecs-cluster"
  tags = {
    Name = "laravel-ecs-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "laravel-ecs-cp" {
  cluster_name = aws_ecs_cluster.laravel-ecs-cluster.name

  capacity_providers = [aws_ecs_capacity_provider.laravel-ecs-cp.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.laravel-ecs-cp.name
  }
}

resource "aws_ecs_capacity_provider" "laravel-ecs-cp" {
  name = "laravel-ecs-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.laravel-asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 85
    }
  }
}

resource "aws_ecs_task_definition" "laravel-task-definition" {
  family                = "laravel-task-definition"
  container_definitions = file("./container-definitions/container-def.json")
  network_mode          = "bridge"
  execution_role_arn    = aws_iam_role.ecs_task-role.arn

  tags = {
    Name = "laravel-task-definition"
  }
}

resource "aws_ecs_service" "laravel-ecs" {
  name            = "laravel-ecs"
  cluster         = aws_ecs_cluster.laravel-ecs-cluster.id
  task_definition = aws_ecs_task_definition.laravel-task-definition.arn
  desired_count   = 2
  iam_role        = aws_iam_role.ecs-service-role.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.laravel-tg.arn
    container_name   = "laravel-app"
    container_port   = 80
  }
  launch_type = "EC2"

}

#Create Security Group
resource "aws_security_group" "laravel-ecs-sg" {
  name   = "laravel-ecs-sg"
  vpc_id = aws_vpc.laravel-vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.laravel-alb-sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "name" = "laravel-ecs-sg"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/laravel-container"
  tags = {
    "env"       = "dev"
    "createdBy" = "mariana"
  }
}
