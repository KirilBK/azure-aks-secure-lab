variable "subscription_id" {
  description = "Azure subscription ID (Azure for Students). Required by azurerm v4."
  type        = string
}

variable "owner_alias" {
  description = "Short alias used to build globally-unique resource names (lowercase, no spaces)."
  type        = string
  default     = "kbk"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.owner_alias))
    error_message = "owner_alias must be 2-10 lowercase letters/digits to keep resource names valid."
  }
}

variable "resource_group_name" {
  description = "Resource group name. Portfolio-friendly rename of the exam's RG-RetakeA."
  type        = string
  default     = "rg-aks-secure-lab"
}

variable "location" {
  type        = string
  default     = "switzerlandnorth"
}

variable "environment" {
  type    = string
  default = "lab"
}

variable "aks_node_count" {
  description = "AKS node count. One node keeps it inside Student quota."
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "VM size for the AKS node. B-series is the cheapest that runs the workload."
  type        = string
  default     = "Standard_B2s"
}

variable "sql_admin_login" {
  description = "Local SQL admin login (kept for break-glass; apps use Entra/Key Vault, not this)."
  type        = string
  default     = "sqladmin"
}

variable "my_ip_address" {
  description = "Your current public IP, used to open the SQL firewall for initial DB seeding only."
  type        = string
}
