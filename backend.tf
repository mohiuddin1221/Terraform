terraform {
  backend "s3" {
    bucket = "topu-terraform"
    key    = "state-file"
    region = "us-east-1"
    dynamodb_table = "terraform-table"
  }
}