provider "aws" {}

resource "aws_vpc" "main" {
  tags = {
    Name = "UP247-VPC"
  }
}
resource "aws_nat_gateway" "nat" {
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"
  tags = {
    Name = "up247-nat-gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
