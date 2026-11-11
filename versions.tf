terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "reconquista-tfstate-362457597483"
    key          = "p2/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
