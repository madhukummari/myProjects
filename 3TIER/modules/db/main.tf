resource "aws_db_subnet_group" "dbsubnetgroup" {
    name = "dbsubnetgroup"
    subnet_ids = var.db_subnet_ids
    tags = {
        Name = "DBSubnetGroup"
    }
}

data "aws_ssm_parameter" "username" {
    name = "/db/username"
}

data "aws_ssm_parameter" "password" {
    name = "/db/password"
}

resource "aws_db_instance" "dbinstance" {
    identifier = var.identifier
    allocated_storage = var.allocated_storage
    engine = var.engine
    engine_version = var.engine_version
    instance_class = var.instance_class
    db_name = var.db_name
    username = data.aws_ssm_parameter.username.value
    password = data.aws_ssm_parameter.password.value
    db_subnet_group_name = aws_db_subnet_group.dbsubnetgroup.name
    vpc_security_group_ids = var.vpc_security_group_ids
    skip_final_snapshot = true
    tags = {
        Name = "MyDBInstance" 
    }
  
}