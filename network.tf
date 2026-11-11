resource "aws_vpc" "onprem" {
  provider = aws.onprem

  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "p2-onprem-vpc"
  }
}

resource "aws_internet_gateway" "onprem" {
  provider = aws.onprem

  vpc_id = aws_vpc.onprem.id

  tags = {
    Name = "p2-onprem-igw"
  }
}

resource "aws_subnet" "onprem_public" {
  provider = aws.onprem

  vpc_id     = aws_vpc.onprem.id
  cidr_block = "172.16.0.0/24"

  tags = {
    Name = "p2-onprem-public"
  }
}

resource "aws_route_table" "onprem_public" {
  provider = aws.onprem

  vpc_id = aws_vpc.onprem.id

  tags = {
    Name = "p2-onprem-public"
  }
}

resource "aws_route" "onprem_public_internet" {
  provider = aws.onprem

  route_table_id         = aws_route_table.onprem_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.onprem.id
}

resource "aws_route_table_association" "onprem_public" {
  provider = aws.onprem

  subnet_id      = aws_subnet.onprem_public.id
  route_table_id = aws_route_table.onprem_public.id
}
