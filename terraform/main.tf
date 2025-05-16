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
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "s3" {
  source        = "./modules/s3"
  aws_region    = var.aws_region
  bucket_prefix = "nyc-taxi-pipeline"
  account_id    = data.aws_caller_identity.current.account_id
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
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
  secrets_manager_read_access_arns = []
}
