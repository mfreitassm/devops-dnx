variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "az_count" {
  default     = "3"
  description = "number of availability zones"
}

variable "health_check_path" {
  default = "/"
}

variable "key_name" {
  type        = string
  description = "The name for ssh key, used for aws_launch_configuration"
}

variable "db_password" {
  description = "Database Password"
  type        = string
}

variable "db_username" {
  description = "Database Username"
  type        = string
}
