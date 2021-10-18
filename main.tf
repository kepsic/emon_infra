## Create main.tf
# ref https://cloudaffaire.com/how-to-deploy-a-lamp-stack-in-aws-using-terraform/
#creates VPC, one public subnet, two private subnets, one EC2 instance and one MYSQL RDS instance
# aws provider
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


terraform {
  backend "s3" {
    bucket         = "lampstack-terraformbackend"
    key            = "terraform"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lampstack-lock"
  }
}


resource "aws_key_pair" "web" {
  key_name   = "lampstack-key"
  public_key = file("lampstack_key.pub")
}

# get AZ's details
data "aws_availability_zones" "availability_zones" {}

# create VPC
resource "aws_vpc" "lampstack_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "lampstack_vpc"
  }
}

# create public subnet
resource "aws_subnet" "lampstack_vpc_public_subnet" {
  vpc_id                  = aws_vpc.lampstack_vpc.id
  cidr_block              = var.subnet_one_cidr
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "lampstack_vpc_public_subnet"
  }
}
# create private subnet one
resource "aws_subnet" "lampstack_vpc_private_subnet_one" {
  vpc_id            = aws_vpc.lampstack_vpc.id
  cidr_block        = element(var.subnet_two_cidr, 0)
  availability_zone = data.aws_availability_zones.availability_zones.names[0]
  tags = {
    Name = "lampstack_vpc_private_subnet_one"
  }
}
# create private subnet two
resource "aws_subnet" "lampstack_vpc_private_subnet_two" {
  vpc_id            = aws_vpc.lampstack_vpc.id
  cidr_block        = element(var.subnet_two_cidr, 1)
  availability_zone = data.aws_availability_zones.availability_zones.names[1]
  tags = {
    Name = "lampstack_vpc_private_subnet_two"
  }
}
# create internet gateway
resource "aws_internet_gateway" "lampstack_vpc_internet_gateway" {
  vpc_id = aws_vpc.lampstack_vpc.id
  tags = {
    Name = "lampstack_vpc_internet_gateway"
  }
}

# create public route table (assosiated with internet gateway)
resource "aws_route_table" "lampstack_vpc_public_subnet_route_table" {
  vpc_id = aws_vpc.lampstack_vpc.id
  route {
    cidr_block = var.route_table_cidr
    gateway_id = aws_internet_gateway.lampstack_vpc_internet_gateway.id
  }
  tags = {
    Name = "lampstack_vpc_public_subnet_route_table"
  }

}

# create private subnet route table
resource "aws_route_table" "lampstack_vpc_private_subnet_route_table" {
  vpc_id = aws_vpc.lampstack_vpc.id
  tags = {
    Name = "lampstack_vpc_private_subnet_route_table"
  }
}
# create default route table
resource "aws_default_route_table" "lampstack_vpc_main_route_table" {
  default_route_table_id = aws_vpc.lampstack_vpc.default_route_table_id
  tags = {
    Name = "lampstack_vpc_main_route_table"
  }
}
# assosiate public subnet with public route table
resource "aws_route_table_association" "lampstack_vpc_public_subnet_route_table" {
  subnet_id      = aws_subnet.lampstack_vpc_public_subnet.id
  route_table_id = aws_route_table.lampstack_vpc_public_subnet_route_table.id
}
# assosiate private subnets with private route table
resource "aws_route_table_association" "lampstack_vpc_private_subnet_one_route_table_assosiation" {
  subnet_id      = aws_subnet.lampstack_vpc_private_subnet_one.id
  route_table_id = aws_route_table.lampstack_vpc_private_subnet_route_table.id
}
resource "aws_route_table_association" "lampstack_vpc_private_subnet_two_route_table_assosiation" {
  subnet_id      = aws_subnet.lampstack_vpc_private_subnet_two.id
  route_table_id = aws_route_table.lampstack_vpc_private_subnet_route_table.id
}

