provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "onprem"
  region = "us-west-2"
}
