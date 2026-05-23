terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  
   backend "azurerm" {
     resource_group_name  = "rg-tfstate"
     storage_account_name = "sttfstatekbk"
     container_name       = "tfstate"
     key                  = "aks-secure-lab.tfstate"
   }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}


data "azurerm_client_config" "current" {}

locals {
  suffix = lower(replace(var.owner_alias, "/[^a-z0-9]/", ""))

  common_tags = {
    project     = "aks-secure-lab"
    owner       = var.owner_alias
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}
