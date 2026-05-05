variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_a_cidr" {
  type = string
}

variable "public_subnet_b_cidr" {
  type = string
}

variable "app_subnet_a_cidr" {
  type = string
}

variable "app_subnet_b_cidr" {
  type = string
}

variable "db_subnet_a_cidr" {
  type = string
}

variable "db_subnet_b_cidr" {
  type = string
}

variable "az_a" {
  type = string
}

variable "az_b" {
  type = string
}
variable "public_rt" {
  type = string

}
variable "private_rt" {
  type = string

}
variable "instance_type" {
  description = "EC2 instance type for both web and app servers"
  type        = string
}
variable "db_identifier" {
  description = "The name of the database instance"
  type        = string
  default     = "mydbinstance"

}
variable "db_allocated_storage" {
  description = "The amount of storage to allocate for the database instance"
  type        = number
  default     = 20
}
variable "db_engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
}
variable "db_engine_version" {
  description = "The version of the database engine to use"
  type        = string
  default     = "8.0"
}
variable "db_instance_class" {
  description = "The instance class to use for the database instance"
  type        = string
  default     = "db.t2.micro"
}
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "mydatabase"
}
variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DB snapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted. You must specify a final DB snapshot identifier in order to delete a DB instance when skip_final_snapshot is false."
  type        = bool
  default     = true
}

