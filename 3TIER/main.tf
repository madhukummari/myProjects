module "vpc" {
  source = "./modules/vpc"

  region = var.region

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr

  public_subnet_a_cidr = var.public_subnet_a_cidr
  public_subnet_b_cidr = var.public_subnet_b_cidr

  app_subnet_a_cidr = var.app_subnet_a_cidr
  app_subnet_b_cidr = var.app_subnet_b_cidr

  db_subnet_a_cidr = var.db_subnet_a_cidr
  db_subnet_b_cidr = var.db_subnet_b_cidr

  az_a = var.az_a
  az_b = var.az_b
  public_rt = var.public_rt
  private_rt = var.private_rt
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  


}
module "web" {
  source = "./modules/web"

  public_subnet_ids = module.vpc.publicsubnet_ids
  role = module.security.SSM_role_name
  security_groups = module.security.sg-outs["web"]
  instance_type = var.instance_type
}

module "app" {
  source = "./modules/app"

  private_subnet_ids = module.vpc.privatesubnet_ids
  role = module.security.SSM_role_name
  security_groups = module.security.sg-outs["app"]
  instance_type = var.instance_type
}
module "db" {
  source = "./modules/db"
  identifier = var.db_identifier
  allocated_storage = var.db_allocated_storage
  engine = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  db_name = var.db_name
  vpc_security_group_ids = module.security.sg-outs["db"]
  skip_final_snapshot = var.skip_final_snapshot
  db_subnet_ids = module.vpc.db_subnet_ids
}

