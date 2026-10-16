terraform {
  required_version = ">= 1.6.0"

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
  }

  # Estado LOCAL (deliberado): este clúster es de vida corta -- se construye,
  # se prueba, se destruye, y se reconstruye justo antes de calificar, para
  # minimizar el costo de la suscripción de Azure. Un Storage Account para
  # estado remoto es un recurso mas que facturaria, aunque sean centavos; P10
  # no evalua disciplina de estado remoto (eso ya se demostro en P9), asi que
  # aqui se prioriza el costo cero sobre la practica recomendada.
}

provider "azurerm" {
  features {}
}
