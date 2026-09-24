# ---------------------------------------------------------------------------
# Continuidad de los secretos.
#
# Las llaves privadas de Sealed Secrets se respaldan (scripts/backup-sealed-key.ps1)
# en Azure Key Vault, fuera del clúster. Aqui se leen y se recrean en kube-system
# ANTES de que ArgoCD instale el controlador (la app raiz depende de este
# recurso). El controlador carga al arrancar todo Secret con la etiqueta
# sealedsecrets.bitnami.com/sealed-secrets-key, asi que los SealedSecret del
# repositorio siguen siendo descifrables en el clúster reconstruido.
#
# Primera instalacion: el secreto vale "[]" (0 llaves); el controlador genera la
# suya y bootstrap.ps1 la respalda al terminar.
# ---------------------------------------------------------------------------

data "azurerm_key_vault" "p9" {
  name                = var.key_vault_name
  resource_group_name = var.persistent_resource_group
}

data "azurerm_key_vault_secret" "sealed_secrets_keys" {
  name         = var.sealed_secrets_secret_name
  key_vault_id = data.azurerm_key_vault.p9.id
}

locals {
  sealed_secrets_keys = jsondecode(data.azurerm_key_vault_secret.sealed_secrets_keys.value)
}

resource "kubectl_manifest" "sealed_secrets_key" {
  count = nonsensitive(length(local.sealed_secrets_keys))

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    type       = "kubernetes.io/tls"
    metadata = {
      name      = local.sealed_secrets_keys[count.index].name
      namespace = "kube-system"
      labels = {
        "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
      }
    }
    data = {
      "tls.crt" = local.sealed_secrets_keys[count.index].crt
      "tls.key" = local.sealed_secrets_keys[count.index].key
    }
  })

  sensitive_fields = ["data"]

  depends_on = [azurerm_kubernetes_cluster.aks]
}
