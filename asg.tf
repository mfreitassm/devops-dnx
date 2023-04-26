data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon", "self"]
}

resource "aws_security_group" "laravel-ec2-sg" {
  name        = "allow-all-ec2"
  description = "allow all"
  vpc_id      = aws_vpc.laravel-vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "laravel-ec2-sg"
  }
}

resource "aws_launch_configuration" "laravel-asg-lc" {
  name          = "laravel-asg-lc"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  lifecycle {
    create_before_destroy = true
  }
  iam_instance_profile        = aws_iam_instance_profile.laravel-ecs_service_role.name
  key_name                    = var.key_name
  security_groups             = [aws_security_group.laravel-ec2-sg.id]
  associate_public_ip_address = false
  user_data                   = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=laravel-ecs-cluster" >> /etc/ecs/ecs.config
EOF
}

resource "aws_autoscaling_group" "laravel-asg" {
  name                      = "laravel-asg"
  launch_configuration      = aws_launch_configuration.laravel-asg-lc.name
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = aws_subnet.private.*.id
  target_group_arns     = [aws_lb_target_group.laravel-tg.arn]
  protect_from_scale_in = true
  lifecycle {
    create_before_destroy = true
  }
}
