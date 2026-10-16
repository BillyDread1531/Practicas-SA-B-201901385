<#
.SYNOPSIS
  Apaga TODO lo de la Practica 10 (destruye el resource group completo) para
  que el costo de Azure vuelva a cero mientras no se este trabajando.

.DESCRIPTION
  Reconstruir despues es un solo comando: scripts\bootstrap.ps1 (~10-15 min).
#>
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$p10 = Split-Path $PSScriptRoot -Parent
$tf = Join-Path $p10 'terraform'

if (-not $Force) {
    $resp = Read-Host "Esto destruye el cluster aks-sa-p10 y el resource group rg-sa-p10. Escribir 'si' para continuar"
    if ($resp -ne 'si') { Write-Host 'Cancelado.'; exit 0 }
}

terraform "-chdir=$tf" destroy -auto-approve -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform destroy fallo' }
Write-Host "Listo. rg-sa-p10 eliminado. Costo de P10 vuelve a 0."
