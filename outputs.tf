output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "asg_names" {
  description = "Names of the ASGs"
  value       = { for k, v in aws_autoscaling_group.env : k => v.name }
}

