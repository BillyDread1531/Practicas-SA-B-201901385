terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }

  # Estado remoto con bloqueo (lease de Azure Blob). Stack independiente del
  # clúster: sobrevive a cualquier `terraform destroy` del stack principal.
  backend "azurerm" {
    resource_group_name  = "rg-sa-p9-backend"
    storage_account_name = "sttfstatesa201901385"
    container_name       = "tfstate"
    key                  = "p9-persistent.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}
