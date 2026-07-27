locals {
  name = "bootstrap-gcp-example"

  labels = {
    environment = "example"
    project     = "bootstrap-gcp"
    managed-by  = "terraform"
  }
}
