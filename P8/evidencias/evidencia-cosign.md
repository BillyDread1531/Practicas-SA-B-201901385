# Evidencia de imagen firmada

La verificación se ejecutó contra:

`acrsa201901385.azurecr.io/gateway:1.0.4`

Parámetros usados:

```text
--certificate-identity-regexp 'BillyDread1531/Practicas-SA-B-201901385.*'
--certificate-oidc-issuer 'https://token.actions.githubusercontent.com'
```

Resultado: verificación Cosign exitosa. La firma contiene identidad GitHub Actions del repositorio `BillyDread1531/Practicas-SA-B-201901385` y referencia al workflow `P8 Secure GitOps` con tag `v1.0.4`.

Workflow: [p8-secure-gitops.yml](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/.github/workflows/p8-secure-gitops.yml)
