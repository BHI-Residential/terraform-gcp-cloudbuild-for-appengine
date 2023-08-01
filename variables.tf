variable "workspace" {}

variable "gcp_folder_id" {}
variable "github_org_name" {}
variable "github_repository_name" {}
variable "github_vcs_branch_regex" {
  default = "^main$"
}
variable "build_timeout" { default = "300s" }
variable "machine_type" { default = "" }

variable "appengine_region" {}
variable "appengine_service_name" {}
variable "appengine_vpc_access" {}

variable "envs_requiring_build_approval" {
  type = list(any)
}


variable "plaintext" {}
variable "encrypted" {}

locals {
  plaintext = var.plaintext
  encrypted = var.encrypted

  variable_subsitition_step = [{
    name       = "launcher.gcr.io/google/ubuntu2004"
    entrypoint = "bash"
    args = [
      "-c",
      "curl -s https://raw.githubusercontent.com/GlueOps/gcp-cloudbuild-substitution-variables/v0.1.0/gcsvh.sh | bash"
    ]
    env = [for k, v in local.all_vars : "${trim(k, "_")}=$${_${k}}"]
  }]

  vpc_access_connector_step = {
    name       = "launcher.gcr.io/google/ubuntu2004"
    entrypoint = "bash"
    args = [
      "-c",
      "curl -s https://raw.githubusercontent.com/GlueOps/gcp-app-engine-flexible-configure-vpc/v0.1.0/gaefcv.sh | bash -s ${var.appengine_vpc_access} ${var.workspace}-vpc ${var.workspace}-${var.appengine_region}-private-subnet"
    ]
  }

  plaintext_vars = [for key in local.plaintext[*] : { for k, v in key : k => v[var.workspace] }][0]
  secret_vars    = [for key in data.google_kms_secret.all_secrets[*] : { for k, v in key : k => v.plaintext }][0]
  all_vars       = merge(local.plaintext_vars, local.secret_vars)
}

variable "build_steps" {

  type = list(object(
    {
      name       = string
      entrypoint = string
      args       = list(string)
      env        = list(string)
    }
  ))
}
