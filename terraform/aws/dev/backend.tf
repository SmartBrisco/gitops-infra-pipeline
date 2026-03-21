terraform {
  backend "s3" {
    bucket         = "gitops-infra-pipeline-tfstate"
    key            = "aws/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gitops-infra-pipeline-tflock"
    encrypt        = true
  }
}