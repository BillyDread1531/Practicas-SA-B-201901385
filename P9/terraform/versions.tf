terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-sa-p9-backend"
    storage_account_name = "sttfstatesa201901385"
    container_name       = "tfstate"
    key                  = "p9-platform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}
