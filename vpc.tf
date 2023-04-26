# Create a VPC
resource "aws_vpc" "laravel-vpc" {
  cidr_block = "10.100.0.0/16"

  tags = {
    Name = "laravel-vpc"
  }
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.laravel-vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.laravel-vpc.id

  tags = {
    Name = "laravel-private-${data.aws_availability_zones.available.names[count.index]}"
  }

}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.laravel-vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.laravel-vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "laravel-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# #Create Network ACL for private subnets
# resource "aws_network_acl" "laravel-nacl-private" {
#   vpc_id = aws_vpc.laravel-vpc.id

#   egress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 302
#     action     = "allow"
#     cidr_block = "10.100.0.0/16"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   tags = {
#     Name = "laravel-nacl-private"
#   }
# }

# resource "aws_network_acl_association" "laravel-nacl-association-private" {
#   count          = var.az_count
#   network_acl_id = aws_network_acl.laravel-nacl-private.id
#   subnet_id      = element(aws_subnet.private.*.id, count.index)
# }

# #Create Network ACL for public subnets
# resource "aws_network_acl" "laravel-nacl-public" {
#   vpc_id = aws_vpc.laravel-vpc.id

#  egress {
#     protocol   = "tcp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = "all"
#     to_port    = "all"
#   }
#   egress {
#     protocol   = "tcp"
#     rule_no    = 102
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 103
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   ingress {
#     protocol   = "all"
#     rule_no    = 1
#     action     = "allow"
#     cidr_block = "10.100.0.0/16"
#     from_port  = "all"
#     to_port    = "all"
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 2
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 103
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 105
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   tags = {
#     Name = "laravel-nacl-public"
#   }
# }

# resource "aws_network_acl_association" "laravel-nacl-association-public" {
#   count          = var.az_count
#   network_acl_id = aws_network_acl.laravel-nacl-public.id
#   subnet_id      = element(aws_subnet.public.*.id, count.index)
# }

resource "aws_internet_gateway" "laravel-igw" {
  vpc_id = aws_vpc.laravel-vpc.id
  tags = {
    Name = "laravel-igw"
  }
}

# Create Public Access Route Table
resource "aws_route_table" "laravel-public-crt" {
  vpc_id = aws_vpc.laravel-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.laravel-igw.id
  }

  tags = {
    Name = "laravel-public-crt"
  }
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "eip-nat-gateway" {
  #count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.laravel-igw]
}

resource "aws_nat_gateway" "laravel-natgw" {
  #count     = var.az_count
  #subnet_id = element(aws_subnet.public.*.id, count.index)
  #allocation_id = element(aws_eip.eip-nat-gateway.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id,0)
  allocation_id = aws_eip.eip-nat-gateway.id

  tags = {
    Name = "laravel-natgw"
  }
}

# Create Private Route Table
resource "aws_route_table" "laravel-private-crt" {
  #count  = var.az_count
  vpc_id = aws_vpc.laravel-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.laravel-natgw.id
    #nat_gateway_id = element(aws_nat_gateway.laravel-natgw.*.id, count.index)
  }

  tags = {
    Name = "laravel-private-crt"
  }
}

resource "aws_route_table_association" "private" {
  count     = var.az_count
  subnet_id = element(aws_subnet.private.*.id, count.index)
  #route_table_id = element(aws_route_table.laravel-private-crt.*.id, count.index)
  route_table_id = aws_route_table.laravel-private-crt.id
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.laravel-public-crt.id
  #route_table_id = element(aws_route_table.laravel-public-crt.*.id, count.index)
}
