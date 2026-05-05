data "aws_availability_zones" "available" {
  state = "available"
  
}
##### resources#######

####################################################################
#############################   VPC   #############################
###################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.project_name
  }
}
#####################   Internet Gateway   ########################

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    
    tags = {
        Name = "${var.project_name}-igw"
    }   
  
}
########################################################################
#############################   public SUBNETS   #############################
#######################################################################
resource "aws_subnet" "public_subnets" {
  count = 2  
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? var.public_subnet_a_cidr : var.public_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
  
}


########################################################################
#############################   private SUBNETS   #############################
#######################################################################
locals {
  private_subnets ={
    subnet_a = {
        cidr = var.app_subnet_a_cidr
        az   = data.aws_availability_zones.available.names[0]
        name = "${var.project_name}-private-a"
    }
    subnet_b = {
        cidr = var.app_subnet_b_cidr
        az   = data.aws_availability_zones.available.names[1]
        name = "${var.project_name}-private-b"

  }
    db_subnet_a = {
        cidr = var.db_subnet_a_cidr
        az   = data.aws_availability_zones.available.names[0]
        name = "${var.project_name}-db-a"
    }
    db_subnet_b = {
        cidr = var.db_subnet_b_cidr
        az   = data.aws_availability_zones.available.names[1]
        name = "${var.project_name}-db-b"
}

}

}
resource "aws_subnet" "privateSubnets" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
  
}

  
########################################################################
#############################   route Tables   #############################
#######################################################################

resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.main.id

    tags = {
        Name = var.public_rt
    }
}
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = var.private_rt
    }
}

resource "aws_route_table_association" "public_rt_association" {
  
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "private_rt_association" {
  for_each = aws_subnet.privateSubnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
  
}
