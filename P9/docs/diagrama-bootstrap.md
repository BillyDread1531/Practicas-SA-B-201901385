# Diagrama del bootstrap: orden de reconstrucción y dependencias

Muestra **en qué orden** se reconstruye el sistema tras perder el clúster, **de qué depende cada componente** y
**qué es automático y qué es manual**. El diagrama se dibuja con Mermaid (GitHub lo renderiza directamente);
la versión PlantUML equivalente está en [diagrama-bootstrap.puml](diagrama-bootstrap.puml).

**Leyenda:** 🟥 manual (operador) · 🟦 automático, Terraform · 🟩 automático, ArgoCD (app-of-apps) · 🟨 automático, script de
bootstrap · ⬜ capa persistente (sobrevive al desastre; no se reconstruye, se **lee**).

```mermaid
flowchart TB
    classDef manual fill:#ffd6d6,stroke:#c0392b,color:#000
    classDef tf fill:#d6e9ff,stroke:#2471a3,color:#000
    classDef argo fill:#d8f5d8,stroke:#1e8449,color:#000
    classDef script fill:#fff3c4,stroke:#b7950b,color:#000
    classDef persist fill:#eeeeee,stroke:#566573,color:#000

    subgraph P["CAPA PERSISTENTE — rg-sa-p9-backend (fuera del clúster; NO se destruye)"]
        TFSTATE[("Estado de Terraform<br/>Blob tfstate + lock")]:::persist
        BLOB[("Blob stp9velero201901385/velero<br/>respaldos Velero + repo Kopia")]:::persist
        KV[("Key Vault kv-p9-201901385<br/>llaves de Sealed Secrets")]:::persist
        GIT[("GitHub público<br/>repo GitOps rama p9 + repo de código")]:::persist
    end

    subgraph M["FASE 0 — MANUAL (único paso humano)"]
        LOGIN["az login"]:::manual
        RUN["P9/scripts/bootstrap.ps1<br/>(punto de entrada único)"]:::manual
        LOGIN --> RUN
    end

    subgraph T["FASE 1 — AUTOMÁTICO: Terraform apply"]
        INIT["terraform init<br/>backend remoto con bloqueo"]:::tf
        RG["Resource group rg-sa-p9"]:::tf
        AKS["Clúster AKS aks-sa-p9<br/>2 nodos"]:::tf
        ACR["Rol AcrPull sobre el ACR"]:::tf
        ARGO["ArgoCD (Helm)"]:::tf
        KEYS["Secret con las llaves de<br/>Sealed Secrets en kube-system"]:::tf
        VEL["Velero (Helm) + schedule<br/>velero-p9-platform cada 6 h"]:::tf
        ROOT["Application p9-root-app<br/>(app-of-apps, ns argocd)"]:::tf
        INIT --> RG --> AKS
        AKS --> ACR
        AKS --> ARGO
        ARGO --> KEYS
        ARGO --> VEL
        KEYS --> ROOT
        VEL --> ROOT
    end

    subgraph A["FASE 2 — AUTOMÁTICO: ArgoCD sincroniza apps/ por olas"]
        direction TB
        W0["OLA 0 (en paralelo)<br/>sealed-secrets · argo-rollouts · kyverno"]:::argo
        W1["OLA 1<br/>p8-kyverno-policies<br/>(requiere los CRD de Kyverno)"]:::argo
        W2["OLA 2<br/>sa-platform-dev: microservicios,<br/>PostgreSQL, RabbitMQ, SealedSecret,<br/>Rollout del gateway"]:::argo
        DEC["Controlador descifra el SealedSecret<br/>con la llave restaurada"]:::argo
        W0 --> W1 --> W2 --> DEC
    end

    subgraph S["FASE 3 — AUTOMÁTICO: script de bootstrap (mismo comando)"]
        WAIT["Espera apps Synced/Healthy,<br/>SealedSecret Synced, pods Ready"]:::script
        RST["restore-datos.ps1<br/>pausa GitOps → borra STS/PVC vacíos →<br/>Velero Restore (statefulsets+pods+PVC+PV) →<br/>PodVolumeRestore repone los datos → reactiva GitOps"]:::script
        VER["verificar.ps1<br/>nodos · GitOps · secretos · Velero ·<br/>Rollout · Kyverno bloquea :latest ·<br/>gateway público · datos"]:::script
        WAIT --> RST --> VER
    end

    RUN ==> INIT
    TFSTATE -. "lee/escribe estado" .-> INIT
    KV -. "lee llaves" .-> KEYS
    BLOB -. "destino de respaldos" .-> VEL
    BLOB -. "origen de la restauración" .-> RST
    GIT -. "lee manifiestos" .-> W0
    ROOT ==> W0
    KEYS -. "el controlador las carga al arrancar" .-> DEC
    DEC ==> WAIT
```

## Dependencias que fuerzan el orden

| Componente | Debe existir antes | Por qué |
|---|---|---|
| ArgoCD | AKS | Se instala con Helm dentro del clúster. |
| Llaves de Sealed Secrets | ArgoCD (namespace), AKS | El controlador solo carga al arrancar las llaves que ya están en `kube-system`; si arranca sin ellas genera una llave nueva y el `SealedSecret` del repositorio queda ilegible. |
| `p9-root-app` | ArgoCD, llaves, Velero | Es lo que dispara el despliegue del resto; se crea al final para que las llaves ya estén. |
| Ola 1 (políticas Kyverno) | Ola 0 (Kyverno) | Los `ClusterPolicy` necesitan los CRD de Kyverno. |
| Ola 2 (plataforma) | Olas 0 y 1 | Usa los CRD de `Rollout` y `SealedSecret`, y está bajo las políticas de admisión. |
| PostgreSQL con datos | `SealedSecret` descifrado, Velero con acceso al Blob | La contraseña de la base viene del secreto; los datos vienen del respaldo. |
| Restauración de datos | Ola 2 lista y política Kyverno con la excepción `restore-wait` | Sin la excepción, Kyverno rechaza el pod restaurado y el volumen queda vacío. |

## Qué es manual y qué no

- **Manual:** `az login` y lanzar `bootstrap.ps1`. Nada más durante la recuperación.
- **Manual, una sola vez y antes de cualquier desastre** (preparación, no recuperación): aplicar
  `P9/terraform-persistent` (crea el Blob y el Key Vault) y ejecutar `scripts/backup-sealed-key.ps1` para guardar la llave.
  `bootstrap.ps1` hace este último paso solo en la primera instalación (Key Vault vacío).
- **Límite conocido (no automatizable):** si se pierde también la capa persistente (Blob, Key Vault) o el repositorio
  GitHub, este procedimiento no puede recuperar los datos ni las llaves. Ver `informe-dr.md`, sección de brecha.
