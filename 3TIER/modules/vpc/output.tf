output "publicsubnet_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}

output "privatesubnet_ids" {
  value = [for s in aws_subnet.privateSubnets : s.id]
}

output "db_subnet_ids" {
  value = {
    for key, value in aws_subnet.privateSubnets :
    key => value.id if strcontains(key, "db")
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}