provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "velero" {
  name                     = var.velero_storage_account_name
  resource_group_name      = azurerm_resource_group.p9.name
  location                 = azurerm_resource_group.p9.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    practica = "P9"
    servicio = "velero"
  }
}

resource "azurerm_storage_container" "velero" {
  name                  = var.velero_blob_container_name
  storage_account_name  = azurerm_storage_account.velero.name
  container_access_type = "private"
}

resource "helm_release" "velero" {
  name              = "velero"
  repository        = "https://vmware-tanzu.github.io/helm-charts"
  chart             = "velero"
  version           = "8.0.0"
  namespace         = "velero"
  create_namespace  = true
  disable_crd_hooks = true

  values = [yamlencode({
    deployNodeAgent = true
    upgradeCRDs     = false
    snapshotsEnabled = false

    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }

    nodeAgent = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }

    configuration = {
      backupStorageLocation = [{
        name     = "default"
        provider = "azure"
        bucket   = azurerm_storage_container.velero.name
        config = {
          resourceGroup           = azurerm_resource_group.p9.name
          storageAccount          = azurerm_storage_account.velero.name
          subscriptionId          = data.azurerm_client_config.current.subscription_id
          useAAD                  = "false"
          storageAccountKeyEnvVar = "AZURE_STORAGE_ACCOUNT_ACCESS_KEY"
        }
      }]
      defaultVolumesToFsBackup = true
    }

    credentials = {
      useSecret = true
      secretContents = {
        cloud = <<-EOT
          AZURE_SUBSCRIPTION_ID=${data.azurerm_client_config.current.subscription_id}
          AZURE_TENANT_ID=${data.azurerm_client_config.current.tenant_id}
          AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${azurerm_storage_account.velero.primary_access_key}
        EOT
      }
    }

    initContainers = [{
      name  = "velero-plugin-for-azure"
      image = "velero/velero-plugin-for-microsoft-azure:v1.10.1"
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "128Mi"
        }
      }
      volumeMounts = [{
        mountPath = "/target"
        name      = "plugins"
      }]
    }]

    schedules = {
      p9-platform = {
        schedule = var.velero_schedule
        template = {
          ttl                      = var.velero_retention
          includedNamespaces       = ["sa-p8"]
          includeClusterResources  = true
          snapshotVolumes          = false
          defaultVolumesToFsBackup = true
        }
      }
    }
  })]

  depends_on = [azurerm_storage_container.velero, helm_release.argocd]
}