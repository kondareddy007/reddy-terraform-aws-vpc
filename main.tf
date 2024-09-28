 resource "aws_vpc" "main" {
   cidr_block = var.vpc_cidr
   enable_dns_hostnames = var.enable_dns_hostnames

   tags = merge(
    var.common_tgs, 
    var.vpc_tags,
    {
        Name = local.name
    }
    )
}

#Internet GateWay
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tgs,
    var.vpc_tags,
    {
        Name = local.name
    }
  )
}

#Public Subnet
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.azs_names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    var.common_tgs,
    var.public_subnet_tags,
    {
        Name = "${local.name}-public-${local.azs_names[count.index]}"
    }
  )
}

#Private Subnet
 resource "aws_subnet" "private" {
   count = length(var.private_subnet_cidr)
   vpc_id = aws_vpc.main.id
   cidr_block = var.private_subnet_cidr[count.index]
   availability_zone = local.azs_names[count.index]
   tags = merge(
    var.common_tgs,
    var.private_subnet_tags,
    {
      Name = "${local.name}-private-${local.azs_names[count.index]}"
    }
   )
 }

 #Database Subnet
 resource "aws_subnet" "database" {
   count = length(var.database_subnet_cidr)
   vpc_id = aws_vpc.main.id
   cidr_block = var.database_subnet_cidr[count.index]
   availability_zone = local.azs_names[count.index]
   tags = merge(
    var.common_tgs,
    var.database_subnet_tags,
    {
      Name = "${local.name}-database-${local.azs_names[count.index]}"
    }
   )
 }
 #Database subnet group  
 resource "aws_db_subnet_group" "default" {
  name       = "${local.name}"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${local.name}"
  }
 }

 # Elastic IP
 resource "aws_eip" "eip" {
   domain = "vpc"
 }

 # NAT gateWay
 resource "aws_nat_gateway" "ngw" {
   allocation_id = aws_eip.eip.id
   subnet_id = aws_subnet.public[0].id
   tags = merge(
    var.common_tgs,
    var.nat_gateway_tags,
    {
      Name = "${local.name}"
    }
   )

   # To ensure proper ordering, it is recommended to add explicitly on the internet gateway for the VPC
   depends_on = [ aws_internet_gateway.igw ]
 }

 # Public route table
 resource "aws_route_table" "public" {
   vpc_id = aws_vpc.main.id
   tags = merge(
    var.common_tgs,
    var.public_route_table_tags,
    {
       Name = "${local.name}-public"
    }
   )
 }

 # Private route table
 resource "aws_route_table" "private" {
   vpc_id = aws_vpc.main.id
   tags = merge(
    var.common_tgs,
    var.private_route_table_tags,
    {
       Name = "${local.name}-private"
    }
   )
 }

 # Database route table
 resource "aws_route_table" "database" {
   vpc_id = aws_vpc.main.id
   tags = merge(
    var.common_tgs,
    var.database_route_table_tags,
    {
       Name = "${local.name}-database"
    }
   )
 }

 #public route
 resource "aws_route" "public_route" {
   route_table_id = aws_route_table.public.id
   destination_cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }

 #privaet route
 resource "aws_route" "private_route" {
   route_table_id = aws_route_table.private.id
   destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id =  aws_nat_gateway.ngw.id
 }

 #database route
 resource "aws_route" "database_route" {
   route_table_id = aws_route_table.database.id
   destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.ngw.id
 }

 #public route table association
 resource "aws_route_table_association" "public" {
   count = length(var.public_subnet_cidr)
   subnet_id = element(aws_subnet.public[*].id, count.index)
   route_table_id = aws_route_table.public.id
 }

 #private route table association
 resource "aws_route_table_association" "private" {
   count = length(var.private_subnet_cidr)
   subnet_id = element(aws_subnet.private[*].id, count.index)
   route_table_id = aws_route_table.private.id
 }

 #database route table association
 resource "aws_route_table_association" "database" {
   count = length(var.database_subnet_cidr)
   subnet_id = element(aws_subnet.database[*].id, count.index)
   route_table_id = aws_route_table.database.id
 }
