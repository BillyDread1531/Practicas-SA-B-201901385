variable "location" {
  description = "Región de Azure (elegida por latencia/disponibilidad, no por costo: el costo de cómputo es igual en todas las regiones estándar de EE. UU.)"
  type        = string
  default     = "eastus"
}

variable "node_vm_size" {
  description = "Tamaño del único nodo del clúster. Standard_B2ms (2 vCPU, 8GiB, burstable) es la opción mas economica con RAM suficiente para alojar ArgoCD + Kyverno + Argo Rollouts + Sealed Secrets + los 5 microservicios + Postgres + el stack de observabilidad completo (Prometheus, Grafana, Loki, Tempo, OTel Collector, Alertmanager) en un solo nodo."
  type        = string
  default     = "Standard_B2ms"
}

variable "node_count" {
  description = "1 solo nodo: P10 no evalúa resiliencia ante pérdida de nodo (eso fue P9); minimizar nodos minimiza el costo por hora."
  type        = number
  default     = 1
}

variable "gitops_repo_url" {
  type    = string
  default = "https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git"
}

variable "gitops_revision" {
  description = "Rama del repositorio GitOps que contiene el app-of-apps de P10"
  type        = string
  default     = "p10"
}
