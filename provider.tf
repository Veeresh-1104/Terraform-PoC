terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"

    }

  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
  //Better Approach : Can pass profile name through CMD when applying
  profile = "sbx"
}