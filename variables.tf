variable "workspace" {}
variable "uri"{}
variable "alert_cpu_usage_threshold" {
  default     = 0.9 #percentage
  description = "The threshold for the CPU usage alert as a Percentage between 0 and 1. Example: 0.6"
}
variable "alert_response_latency_threshold" {
  default     = 10000
  description = "The threshold for high latency as a number of milliseconds. Example: 10000"
}

variable "alert_5xx_threshold" {
  default     = 5
  description = "value of 5xx errors to trigger alert. Example: 5"
}
variable "alert_email" {
  description = "The email address to send alerts to. Example: alerts@example.com"
}
variable "encrypted_slack_webhook_url" {
  description = "The webhook URL for slack to send deployment notifications to. Example: https://hooks.slack.com/services/XXXXXXXXX/YYYYYYYY/ZZZZZZZZZZZZZZ"
}
variable "slack_channel_for_deploy_notifications" {
  description = "The slack channel to send deployment notifications to. Example: #deployments"
}

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

variable "trigger_yaml_name" {
  
}
variable "plaintext" {}
variable "encrypted" {}

locals {
  plaintext = var.plaintext
  encrypted = var.encrypted
  plaintext_vars = [for key in local.plaintext[*] : { for k, v in key : k => v[var.workspace] }][0]
  secret_vars    = [for key in data.google_kms_secret.all_secrets[*] : { for k, v in key : k => v.plaintext }][0]
  all_vars       = merge(local.plaintext_vars, local.secret_vars)
}

