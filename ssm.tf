# resource "aws_ssm_parameter" "laravel_secrets" {
#   for_each = var.parameters

#   name  = each.key
#   type  = each.value.type
#   value = each.value.value

#   tags = {
#     Environment = var.environment
#     Application = var.application
#   }
# }
