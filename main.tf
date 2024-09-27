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