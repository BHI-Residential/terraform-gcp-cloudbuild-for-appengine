data "google_kms_key_ring" "default" {
  project  = local.project_name
  name     = var.workspace
  location = "global"
}

data "google_kms_crypto_key" "default" {
  name     = "encrypt_decrypt-${var.workspace}"
  key_ring = data.google_kms_key_ring.default.id
}

data "google_kms_secret" "all_secrets" {
  for_each = local.encrypted

  crypto_key = data.google_kms_crypto_key.default.id
  ciphertext = local.encrypted[each.key][var.workspace]

}

data "google_kms_secret" "slack_webhook_url" {

  crypto_key = data.google_kms_crypto_key.default.id
  ciphertext = var.encrypted_slack_webhook_url

}

