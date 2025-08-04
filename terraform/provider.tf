provider "aws" {
  region = "us-east-1"
  
}
terraform {
  backend "s3" {
    bucket         = "stationary-remote-backend"
    key            = "terraform/state"
    region         = "us-east-1"
    
  }
}
  
