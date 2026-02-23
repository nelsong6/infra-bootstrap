variable "github_owner" {
  type = string
}

variable "github_pat" {
  type      = string
  sensitive = true
}

variable "auth0_client_secret" {
  type      = string
  sensitive = true
}

variable "spacelift_api_key_id" {
  type      = string
  sensitive = true
}

variable "spacelift_api_key_secret" {
  type      = string
  sensitive = true
}
