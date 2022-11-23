# Allows the Vault provider create a child token.
path "auth/token/create" {
 capabilities = ["update"]
}
# Allow the creation of a Kubernetes ServiceAccount
path "kubernetes/creds/cicd-write" {
  capabilities = ["create", "update"]
}
