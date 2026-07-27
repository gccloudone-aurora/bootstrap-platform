locals {
  azure_resource_attributes = {
    department_code = "Gc"
    owner           = "Aur"
    project         = "boot"
    environment     = "dev"
    location        = "Canada Central"
    instance        = 0
  }

  tags = {
    Environment = "example"
    Project     = "bootstrap-azure"
    ManagedBy   = "terraform"
  }
}
