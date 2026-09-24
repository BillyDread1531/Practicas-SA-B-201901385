data "azurerm_client_config" "current" {}

# Destino de los respaldos: Storage Account de la capa PERSISTENTE
# (P9/terraform-persistent). Esta fuera del clúster y del estado que se
# destruye en el DR, por lo que los respaldos sobreviven a la perdida total.
data "azurerm_storage_account" "velero" {
  name                = var.velero_storage_account_name
  resource_group_name = var.persistent_resource_group
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

    # Requests bajos (uso real < 10 m) para que un solo nodo pueda alojar todo el sistema.
    resources = {
      requests = {
        cpu    = "25m"
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
          cpu    = "25m"
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
        bucket   = var.velero_blob_container_name
        config = {
          resourceGroup           = var.persistent_resource_group
          storageAccount          = data.azurerm_storage_account.velero.name
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
          AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${data.azurerm_storage_account.velero.primary_access_key}
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

  depends_on = [helm_release.argocd]
}