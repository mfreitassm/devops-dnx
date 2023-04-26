terraform {
  backend "s3" {
    bucket = "laravel-terraform-dnx"
    key    = "state"
    region = "ap-southeast-2"
  }
}
