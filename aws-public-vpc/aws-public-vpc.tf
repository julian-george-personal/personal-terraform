# The account's default VPC (vpc-35e1074f) has had its subnets and internet
# gateway removed (only a dead blackhole route to a deleted IGW remains) —
# not worth adopting into Terraform state, so this provisions a small
# from-scratch VPC instead. Public-only: no NAT gateway, since everything
# using this is expected to be outbound-internet-only batch work (see
# aws-ecs-fargate-scheduled-task).
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "public" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.public.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.public.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
