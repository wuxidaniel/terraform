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
  route {
	  cidr_block = "0.0.0.0/0"
	  nat_gateway_id         = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "up247-private-subnet-routes"
  }
}

# This data source 'reads' the live state of the route table
data "aws_route_table" "check_private" {
  route_table_id = aws_route_table.private.id
}

# This 'check' block warns you if the route breaks
check "nat_gateway_health" {
  assert {
    condition = alltrue([
      for r in data.aws_route_table.check_private.routes :
      r.nat_gateway_id != "" && r.nat_gateway_id != null
      if r.cidr_block == "0.0.0.0/0"
    ])
    error_message = "CRITICAL: The 0.0.0.0/0 route is missing its NAT Gateway ID association!"
  }
}
