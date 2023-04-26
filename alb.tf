#Create Load Balancer Target Group
resource "aws_lb_target_group" "laravel-tg" {
  name        = "laravel-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.laravel-vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
    path                = var.health_check_path
    interval            = 30
  }
}

resource "aws_lb" "laravel-alb" {
  name               = "laravel-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.laravel-alb-sg.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id, aws_subnet.public[2].id]
  enable_deletion_protection = false

  tags = {
    Name = "laravel-alb"
  }
}

resource "aws_lb_listener" "laravel-alb-listener" {
  load_balancer_arn = aws_lb.laravel-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.laravel-tg.arn
  }
}


#Create Security Group
resource "aws_security_group" "laravel-alb-sg" {
  vpc_id = aws_vpc.laravel-vpc.id
  name = "laravel-alb-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "laravel-alb-sg"
  }
}

output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.laravel-alb.dns_name
}
