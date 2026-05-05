output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group to be used in ECS service"
  value       = aws_lb_target_group.fastapi_tg.arn
}
