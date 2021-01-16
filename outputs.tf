#Output vars
output "static_ip_addr" {
  value = aws_instance.worker.public_ip
}