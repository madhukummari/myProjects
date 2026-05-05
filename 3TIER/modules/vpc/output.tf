output "publicsubnet_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "privatesubnet_ids" {
  value = aws_subnet.privateSubnets.*.id
}
output "db_subnet_ids" {
  value = {for key, value in aws_subnet.privateSubnets : key => value.id if contains(key, "db")}
  
}

output "vpc_id" {
  value = aws_vpc.main.id
}