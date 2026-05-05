# ALB S Group ID 
output "alb_sg_id" {
  description = "The ID of the security group for the ALB"
  value       = aws_security_group.alb_sg.id
}

# Fargate Sg Group ID
output "fargate_sg_id" {
  description = "The ID of the security group for the Fargate tasks"
  value       = aws_security_group.fargate_sg.id
}