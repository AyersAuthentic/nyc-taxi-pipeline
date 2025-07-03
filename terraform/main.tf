data "aws_caller_identity" "current" {}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-nyc-taxi"


  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}


terraform {
  backend "s3" {
    bucket       = "nyc-taxi-pipeline-tfstate"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

module "networking" {
  source     = "./modules/networking"
  aws_region = var.aws_region

}

module "s3" {
  source        = "./modules/s3"
  aws_region    = var.aws_region
  bucket_prefix = "nyc-taxi-pipeline"
  account_id    = data.aws_caller_identity.current.account_id
}

module "iam_roles" {
  source = "./modules/iam"

  bronze_bucket_arn = module.s3.bronze_bucket_arn
  silver_bucket_arn = module.s3.silver_bucket_arn
  gold_bucket_arn   = module.s3.gold_bucket_arn

  project_name     = var.project_name
  environment      = var.environment
  account_id       = data.aws_caller_identity.current.account_id
  aws_region       = var.aws_region
  github_org_name  = var.github_org_name
  github_repo_name = var.github_repo_name

  airflow_dags_s3_bucket_arn = module.s3.bronze_bucket_arn
  airflow_logs_s3_bucket_arn = module.s3.bronze_bucket_arn

  #secrets manager arns
  airflow_ec2_role_secret_arns         = [module.secrets_manager.rds_master_password_secret_arn, module.secrets_manager.airflow_admin_password_secret_arn, module.secrets_manager.redshift_admin_password_secret_arn]
  lambda_external_role_secret_arns     = [module.secrets_manager.noaa_api_key_secret_arn]
  terraform_execution_role_secret_arns = []
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id = module.networking.vpc_id

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region


  local_ip_for_ssh         = var.user_ssh_ip
  local_ip_for_airflow_ui  = var.user_airflow_ui_ip
  local_ip_for_metabase_ui = var.user_metabase_ui_ip

  local_ip_for_ssh_2        = var.user_ssh_ip_2
  local_ip_for_airflow_ui_2 = var.user_airflow_ui_ip_2
}


module "secrets_manager" {
  source = "./modules/secrets_manager"

  project_name = var.project_name
  environment  = var.environment
}


module "rds_airflow_db" {
  source = "./modules/rds"


  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region


  # Dependencies from other modules
  private_subnet_ids = module.networking.private_subnets
  rds_allowed_sg_id  = module.security_groups.rds_airflow_sg_id
  master_password    = module.secrets_manager.rds_master_password_value


}



module "redshift_serverless" {
  source = "./modules/redshift"

  project_name                   = var.project_name
  admin_user_password_secret_arn = module.secrets_manager.redshift_admin_password_secret_arn
  redshift_iam_role_arn          = module.iam_roles.redshift_serverless_role_arn
  private_subnet_ids             = module.networking.private_subnets
  public_subnet_ids              = module.networking.public_subnets
  redshift_security_group_id     = module.security_groups.redshift_vpc_sg_id
  admin_user_password            = module.secrets_manager.redshift_admin_password_value

}


module "ec2_airflow" {
  source = "./modules/ec2"

  project_name  = var.project_name
  environment   = var.environment
  instance_type = var.ec2_instance_type
  ec2_key_name  = var.ec2_key_name


  public_subnet_id          = module.networking.public_subnets[0]
  airflow_ec2_sg_id         = module.security_groups.airflow_ec2_sg_id
  iam_instance_profile_name = module.iam_roles.airflow_ec2_instance_profile_name
  user_data_script          = file("${path.module}/../scripts/airflow_setup.sh")

  depends_on = [
    module.secrets_manager,
    module.rds_airflow_db,
    module.redshift_serverless
  ]
}



module "lambda_functions" {
  source = "./modules/lambda"

  project_name       = var.project_name
  environment        = var.environment
  bronze_bucket_name = module.s3.bronze_bucket_id


  lambda_execution_role_arn = module.iam_roles.lambda_external_role_arn
  noaa_api_key_secret_arn   = module.secrets_manager.noaa_api_key_secret_arn


}
