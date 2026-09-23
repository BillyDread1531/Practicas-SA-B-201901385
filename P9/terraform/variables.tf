variable "github_pat" {
  description = "Token de GitHub con acceso de lectura a Practicas-SA-B-201901385 (para que ArgoCD lo clone)"
  type        = string
  sensitive   = true
}

variable "velero_storage_account_name" {
  description = "Nombre globalmente unico de la cuenta Blob externa usada por Velero"
  type        = string
  default     = "stvelerosa201901385"
}

variable "velero_blob_container_name" {
  description = "Contenedor donde Velero almacena los respaldos"
  type        = string
  default     = "velero"
}

variable "velero_schedule" {
  description = "Expresion cron UTC para el respaldo programado"
  type        = string
  default     = "0 */6 * * *"
}

variable "velero_retention" {
  description = "Retencion de cada respaldo de Velero"
  type        = string
  default     = "720h"
}
