# Outputs

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.hashi_vpc.id
}

output "private_subnet_id" {
  description = "The ID of the created private subnet."
  value       = aws_subnet.hashi_private_subnet.id
}

output "public_subnet_id_1" {  # Renamed for clarity
  description = "The ID of the first created public subnet."
  value       = aws_subnet.hashi_public_subnet.id
}

output "public_subnet_id_2" {  # New output for the second public subnet
  description = "The ID of the second created public subnet."
  value       = aws_subnet.hashi_public_subnet_2.id
}

output "aws_internet_gateway_id" {
  description = "The ID of the Internet Gateway used for the public subnet."
  value       = aws_internet_gateway.hashi_internet_gateway.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway used for the private subnet."
  value       = aws_nat_gateway.hashi_nat_gateway.id
}

output "aws_security_group" {
  description = "The ID of the security group used for the EC2 instance."
  value       = aws_security_group.hashi_web_sg.id
}

output "alb_security_group_id" {
  description = "The ID of the security group used for the ALB."
  value       = aws_security_group.hashi_alb_sg.id
}

output "dev_node_instance_id" {
  description = "The ID of the created EC2 instance."
  value       = aws_instance.dev_node.id
}

output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The DNS name of the ALB"
}

output "alb_listener_arn" {
  description = "The ARN of the ALB Listener."
  value       = aws_lb_listener.web_listener.arn
}

output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = aws_lb_target_group.web_tg.arn
}

output "key_pair_name" {
  description = "The name of the key pair used for the EC2 instance."
  value       = aws_key_pair.hashi_auth.key_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM Role used by the EC2 instance."
  value       = aws_iam_role.ssm_role.arn
}

# This output assumes your EC2 instance might have a public IP. 
# Since your instance is in a private subnet, it probably won't, but you can include this just in case.
output "ec2_public_ip" {
  description = "The public IP of the EC2 instance."
  value       = aws_instance.dev_node.public_ip
}