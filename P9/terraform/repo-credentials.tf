resource "kubectl_manifest" "repo_creds" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: practicas-sa-b-201901385-creds
      namespace: argocd
      labels:
        argocd.argoproj.io/secret-type: repository
    stringData:
      type: git
      url: https://github.com/BillyDread1531/Practicas-SA-B-201901385.git
      username: BillyDread1531
      password: ${var.github_pat}
  YAML

  depends_on = [helm_release.argocd]
}
