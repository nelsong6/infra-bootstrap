variable "repo_name" { 
  type = string 
}
variable "repo_owner" { 
  type = string 
  }


variable "spacelift_vcs_app_token" {
  type      = string
  default   = null
  sensitive = true
}