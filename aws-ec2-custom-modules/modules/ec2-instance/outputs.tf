output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.ec2_instance[0].id
}

output "instance_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.ec2_instance[0].public_ip
}