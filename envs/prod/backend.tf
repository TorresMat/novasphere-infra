terraform {
  backend "s3" {
    bucket       = "novasphere-tfstate-mat-635176221694-20261104143933"
    key          = "novasphere/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
