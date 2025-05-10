provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-nyc-taxi"

  # Add default tags to all resources
  default_tags {
    tags = {
      Project     = "nyc-taxi-pipeline"
      Environment = "dev"
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
}
