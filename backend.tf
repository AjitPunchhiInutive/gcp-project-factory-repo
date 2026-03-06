terraform {
  backend "gcs" {
    bucket = "itp-terraform-test"
    prefix = "gcp-project-factory-itp/state"
  }
}
