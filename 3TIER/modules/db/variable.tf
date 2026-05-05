variable "identifier" {
  description = "The name of the database instance"
  type        = string
  default     = "mydbinstance"

}
variable "allocated_storage" {
  description = "The amount of storage to allocate for the database instance"
  type        = number
  default     = 20
}
variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
}
variable "engine_version" {
  description = "The version of the database engine to use"
  type        = string
  default     = "8.0"
}
variable "instance_class" {
  description = "The instance class to use for the database instance"
  type        = string
  default     = "db.t2.micro"
}
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "mydatabase"
}
variable "db_subnet_ids" {
  description = "The name of the DB subnet ids to use for the database instance"
  type        = list(string)

}
variable "vpc_security_group_ids" {
  description = "A list of VPC security groups to associate with the database instance"
  type        = list(string)

}
variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DB snapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted. You must specify a final DB snapshot identifier in order to delete a DB instance when skip_final_snapshot is false."
  type        = bool
  default     = true
}   