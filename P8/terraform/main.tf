terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "namespace" {
  description = "Namespace de la plataforma P8"
  type        = string
  default     = "sa-p8"
}

locals {
  services = [
    "auth",
    "cursos",
    "estudiantes",
    "inscripciones",
    "gateway",
    "cron-insert",
    "cron-resumen",
    "cron-consumer"
  ]
}

# ============================================================
# NAMESPACE
# ============================================================

resource "kubernetes_namespace" "sa_p8" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "sa-platform"
      "app.kubernetes.io/version" = "1.0.0"
      "environment"               = "p8"
      "managed-by"                = "terraform"
    }
  }
}

# ============================================================
# RESOURCE QUOTA
# ============================================================

resource "kubernetes_resource_quota" "sa_p8" {
  metadata {
    name      = "sa-p8-quota"
    namespace = kubernetes_namespace.sa_p8.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"           = "2"
      "requests.memory"        = "2Gi"
      "limits.cpu"             = "4"
      "limits.memory"          = "4Gi"
      "pods"                   = "30"
      "persistentvolumeclaims" = "5"
    }
  }
}

# ============================================================
# LIMIT RANGE
# ============================================================

resource "kubernetes_limit_range" "sa_p8" {
  metadata {
    name      = "sa-p8-limits"
    namespace = kubernetes_namespace.sa_p8.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }

      default = {
        cpu    = "300m"
        memory = "256Mi"
      }

      min = {
        cpu    = "10m"
        memory = "16Mi"
      }
    }
  }
}
resource "kubernetes_service_account" "services" {
  for_each = toset(local.services)

  metadata {
    name      = "${each.key}-sa"
    namespace = kubernetes_namespace.sa_p8.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of"   = "sa-platform"
      "app.kubernetes.io/component" = each.key
      "managed-by"                  = "terraform"
    }
  }

  automount_service_account_token = false
}

# ============================================================
# ROLE
# ============================================================

output "namespace" {
  value = kubernetes_namespace.sa_p8.metadata[0].name
}

output "resource_quota" {
  value = kubernetes_resource_quota.sa_p8.metadata[0].name
}

output "limit_range" {
  value = kubernetes_limit_range.sa_p8.metadata[0].name
}

output "service_accounts" {
  value = [
    for sa in kubernetes_service_account.services :
    sa.metadata[0].name
  ]
}



# ============================================================
# ROLE DE LECTURA
# ============================================================

resource "kubernetes_role" "sa_p8_reader" {
  metadata {
    name      = "sa-p8-reader"
    namespace = kubernetes_namespace.sa_p8.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of" = "sa-platform"
      "managed-by"                = "terraform"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints", "pods", "pods/log", "services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["rollouts"]
    verbs      = ["get", "list", "watch"]
  }
}

# ============================================================
# ROLE BINDINGS DE LECTURA
# ============================================================

resource "kubernetes_role_binding" "service_readers" {
  for_each = toset(local.services)

  metadata {
    name      = "${each.key}-reader"
    namespace = kubernetes_namespace.sa_p8.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of"   = "sa-platform"
      "app.kubernetes.io/component" = each.key
      "managed-by"                  = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.sa_p8_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.services[each.key].metadata[0].name
    namespace = kubernetes_namespace.sa_p8.metadata[0].name
  }
}

output "role" {
  value = kubernetes_role.sa_p8_reader.metadata[0].name
}

output "role_bindings" {
  value = [
    for binding in kubernetes_role_binding.service_readers :
    binding.metadata[0].name
  ]
}
