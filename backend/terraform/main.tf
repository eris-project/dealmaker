terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8"
    }
  }

  backend "s3" {
    bucket = "everythingserverless-us-east-1-terraform-backend"
    key    = "dealmaker"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Service     = var.app_name
      Environment = "dev"
    }
  }
}

module "ochestrator" {
  source   = "./modules/ochestrator"
  app_name = var.app_name
}
