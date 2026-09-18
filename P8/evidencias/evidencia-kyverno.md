# Evidencia de políticas Kyverno

Políticas activas observadas en el clúster:

- `p8-disallow-latest`
- `p8-require-resources`
- `p8-require-non-root`

Manifiestos:

- [01-disallow-latest.yaml](../security/kyverno/01-disallow-latest.yaml)
- [02-require-resources.yaml](../security/kyverno/02-require-resources.yaml)
- [03-require-non-root.yaml](../security/kyverno/03-require-non-root.yaml)

Pendiente de captura: salida del recurso rechazado y su evento de admisión. El verificador confirma las tres políticas activas, pero este archivo no sustituye la evidencia visual del rechazo.
