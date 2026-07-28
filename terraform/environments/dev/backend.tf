# Fill in the bucket/table names from the backend-bootstrap outputs, then run:
#   terraform init
#   terraform workspace new dev      (or: terraform workspace select dev)
#
# Workspaces give you dev/staging/prod state isolation from this same config.
terraform {
  backend "s3" {
    bucket = "eldho-capstone2-tfstate-082846230300"
    key            = "capstone2/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "capstone2-tf-lock"
    encrypt        = true
  }
}
