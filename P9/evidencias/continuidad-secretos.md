# Continuidad de los secretos - evidencia (generada por scripts/evidencia-continuidad.ps1)

Mecanismo: **Sealed Secrets con respaldo de la llave en Azure Key Vault** (externo al cluster) y restauracion
automatica por Terraform. Consulta hecha el 2026-09-24T09:30:34Z UTC sobre el cluster reconstruido. No se imprime ninguna llave.

## Como funciona

1. Las llaves privadas del controlador se respaldan con `scripts/backup-sealed-key.ps1` en el Key Vault
   `kv-p9-201901385` (secreto `sealed-secrets-keys`, actualizado 2026-09-24T07:10:34+00:00). El Key Vault esta en la capa persistente
   (`rg-sa-p9-backend`), fuera del cluster y fuera del estado de Terraform que se destruye.
2. En el bootstrap, `P9/terraform/sealed-secrets-key.tf` lee el secreto y crea los `Secret` de llave en `kube-system`
   **antes** de que ArgoCD cree la aplicacion raiz (dependencia explicita en `bootstrap.tf`), de modo que el controlador
   las carga al arrancar.
3. El controlador se despliega con `--key-renew-period 0` (argumentos reales: `--update-status --key-renew-period 0 --key-prefix sealed-secrets-key --listen-addr :8080 --listen-metrics-addr :8081`), asi la copia del Key Vault no
   se queda obsoleta por rotacion automatica.

## Prueba: las llaves del cluster reconstruido son las del Key Vault

Se compara la huella SHA-256 del certificado publico (`tls.crt`) de cada llave entre el Key Vault y el cluster.

| Llave | Certificado emitido | SHA-256 (Key Vault) | SHA-256 (cluster) | Resultado |
|---|---|---|---|---|
| `sealed-secrets-key6v5m9` | 2026-09-22 | `87bf83c944776730...` | `87bf83c944776730...` | COINCIDE |
| `sealed-secrets-keys4zb4` | 2026-09-23 | `3cb581af820bd7e4...` | `3cb581af820bd7e4...` | COINCIDE |

## Prueba: el SealedSecret del repositorio se descifra

| Comprobacion | Resultado |
|---|---|
| `SealedSecret/sa-platform-secrets` (namespace `sa-p8`) | condicion `Synced` = **True** desde 2026-09-24T09:16:47Z |
| `Secret/sa-platform-secrets` generado por el controlador | existe; claves: DB_PASSWORD, DB_USER, JWT_SECRET, password, postgres-password, RABBITMQ_ERLANG_COOKIE, RABBITMQ_PASSWORD, RABBITMQ_USERNAME, rabbitmq-erlang-cookie, rabbitmq-password |
| Propietario del Secret | `SealedSecret/sa-platform-secrets` |
| Errores `no key could decrypt` en el log del controlador (ultimas 1000 lineas) | **0** |
| Cifrado con la llave restaurada | El `SealedSecret` del repositorio se cifro antes de destruir el cluster; el cluster nuevo nunca vio esa llave salvo por el Key Vault. Que se descifre prueba la continuidad. |

Fragmento del log del controlador (sin valores secretos):

```
time=2026-09-24T09:28:28.286Z level=INFO msg="Searching for existing private [...]
time=2026-09-24T09:28:28.331Z level=INFO msg="registered private [...]
time=2026-09-24T09:28:28.332Z level=INFO msg="registered private [...]
time=2026-09-24T09:28:28.433Z level=INFO msg=Updating key=sa-p8/sa-platform-secrets
time=2026-09-24T09:28:28.499Z level=INFO msg="Event(v1.ObjectReference{Kind:\"SealedSecret\", Namespace:\"sa-p8\", Name:\"sa-platform-secrets\", UID:\"24cb76cb-e700-4f49-973f-f8bf7033c945\", APIVersion:\"bitnami.com/v1alpha1\", ResourceVersion:\"3993\", FieldPath:\"\"}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully"
```
