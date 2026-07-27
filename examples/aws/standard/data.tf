data "terraform_remote_state" "prerequisites" {
  backend = var.prerequisites_remote_state.backend
  config  = var.prerequisites_remote_state.config
}
