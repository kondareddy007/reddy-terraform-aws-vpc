module "roboshop" {
  source = "../reddy-terraform-aws-vpc"
  project_name = var.project_name
  environment = var.environment
  common_tgs = var.common_tgs
  vpc_tags = var.vpc_tags

  #public subnet
  public_subnet_cidr = var.public_subnet_cidr

  #private subnet
  private_subnet_cidr = var.private_subnet_cidr

  #Database subnet
  database_subnet_cidr = var.database_subnet_cidr

  #peering
  is_peering_required = var.is_peering_required
} 