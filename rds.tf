
resource "aws_db_subnet_group" "rds-subnetgroup" {
  name        = "rds-subnetgroup"
  description = "Private Subnet Group RDS - Laravel"
  subnet_ids  = [aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id]
  tags = {
    Name = "laravel DB subnet group"
  }
}

resource "aws_db_instance" "homestead" {
  identifier             = "homestead"
  allocated_storage      = 10
  db_name                = "homestead"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.rds-subnetgroup.id
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_ssm_parameter" "laravel-db-host" {
  name  = "DB_HOST"
  type  = "String"
  value = aws_db_instance.homestead.address
}

resource "aws_ssm_parameter" "laravel-db-password" {
  name  = "DB_PASSWORD"
  type  = "SecureString"
  value = var.db_password
}

resource "aws_ssm_parameter" "laravel-db-username" {
  name  = "DB_USERNAME"
  type  = "SecureString"
  value = var.db_username
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.homestead.address
  sensitive   = false
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.homestead.username
  sensitive   = false
}

#Create Security Group
resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.laravel-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.laravel-ec2-sg.id]
  }
  tags = {
    Name = "rds-sg"
  }
}
