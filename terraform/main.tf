provider "aws" {
    region = var.aws_region

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
        bucket = "nyc-taxi-pipeline-tfstate"
        key    = "terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-state-lock"
        encrypt        = true
    }
}

# Variables
variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string
    default     = "us-east-1"
}

