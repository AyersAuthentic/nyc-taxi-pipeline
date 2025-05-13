provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-nyc-taxi"

  # Add default tags to all resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Configure backend for storing Terraform state
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
  source = "./modules/networking"
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
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
