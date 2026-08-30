output "vpc_id" {
  value = aws_vpc.public.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}
