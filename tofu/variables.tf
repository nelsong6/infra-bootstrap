variable "github_owner" {
  type = string
}

variable "github_pat" {
  type      = string
  sensitive = true
}

variable "cluster_subscription_id" {
  description = "Azure subscription ID for the AKS cluster and its VNet/subnet. Defaults to the primary infra subscription when empty."
  type        = string
  default     = ""
}

variable "cluster_resource_group_name" {
  description = "Resource group name for AKS cluster resources in the cluster subscription."
  type        = string
  default     = "infra"
}
