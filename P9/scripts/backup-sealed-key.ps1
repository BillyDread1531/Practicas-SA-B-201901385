<#
.SYNOPSIS
  Respalda las llaves privadas de Sealed Secrets del clúster en Azure Key Vault.

.DESCRIPTION
  El Key Vault vive en la capa persistente (P9/terraform-persistent), fuera del
  clúster: si el clúster se pierde, `terraform apply` de P9/terraform lee este
  secreto y recrea las llaves ANTES de que arranque el controlador, de modo que
  los SealedSecret del repositorio siguen siendo descifrables.

  Ejecutar: (a) tras la primera instalación, (b) tras cualquier rotación de llave.
  El controlador se despliega con keyrenewperiod=0 (sin rotación automática).
  No imprime ninguna llave.
#>
param(
    [string]$VaultName  = 'kv-p9-201901385',
    [string]$SecretName = 'sealed-secrets-keys'
)
$ErrorActionPreference = 'Stop'

$raw = kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o json
if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer los secretos de kube-system (¿kubectl apunta a aks-sa-p9?)' }
$items = @((($raw -join "`n") | ConvertFrom-Json).items)
if ($items.Count -eq 0) { throw 'No hay llaves de Sealed Secrets en kube-system; nada que respaldar.' }

$keys = @($items | ForEach-Object {
    [ordered]@{ name = $_.metadata.name; crt = $_.data.'tls.crt'; key = $_.data.'tls.key' }
})

$tmp = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($tmp, (ConvertTo-Json -InputObject $keys -Compress -Depth 5), (New-Object Text.UTF8Encoding $false))
    az keyvault secret set --vault-name $VaultName --name $SecretName --file $tmp --encoding utf-8 --content-type application/json --output none
    if ($LASTEXITCODE -ne 0) { throw 'az keyvault secret set falló' }
}
finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }

Write-Host "OK: $($keys.Count) llave(s) de Sealed Secrets respaldadas en Key Vault '$VaultName' (secreto '$SecretName')."
