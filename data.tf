data "terraform_remote_state" "project1" {
  backend = "s3"

  config = {
    bucket = "reconquista-tfstate-362457597483"
    key    = "aws-tgw-centralized-inspection/terraform.tfstate"
    region = "us-west-1"
  }
}
