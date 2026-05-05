data "aws_availability_zones" "availble" {
  state = "available"
}

data "aws_ami_ids" "ami_ids" {
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]

}

locals {
  selected_azs      = slice(data.aws_availability_zones.availble.names, 0, 2) #we are slicing the list to get only first 2 availability zones
  instances_name    = ["Web-A", "Web-B"]
  public_subnet_ids = var.public_subnet_ids

  server_map = {
    for idx, name in local.instances_name :
    "instance-${idx + 1}" => {
      name      = name
      az        = local.selected_azs[idx % length(local.selected_azs)]
      subnet_id = local.public_subnet_ids[idx % length(local.public_subnet_ids)]
    }

  }

}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "WebInstanceProfile"
  role = var.role
}

resource "aws_instance" "webservers" {
  for_each = local.server_map

  ami                  = data.aws_ami_ids.ami_ids.ids[0]
  instance_type        = var.instance_type
  availability_zone    = each.value.az
  subnet_id            = each.value.subnet_id
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name
  security_groups      = var.security_groups
  tags = {
    Name = each.value.name
  }

}