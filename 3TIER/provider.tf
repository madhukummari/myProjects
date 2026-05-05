terraform {
    required_providers {
        
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    backend "s3" {
        bucket         = "terraform-state-bucket-3692"
        key            = "state/terraform-modules.tfstate"
        region         = "ap-south-2"
        encrypt        = true
        dynamodb_table = "terraform-locks"
    }
    }

provider "aws" {
    region = "ap-south-2"
}