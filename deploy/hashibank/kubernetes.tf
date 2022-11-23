# Authenticate to Vault
provider "vault" {
  address = "http://vault.infra.svc:8200"
  auth_login {
    path = "auth/kubernetes/login"

    parameters = {
      role = "tfc"
      jwt  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    }
  }
}

# Request Kubernetes ServiceAccount
data "vault_kubernetes_service_account_token" "token" {
  backend              = "kubernetes"
  role                 = "cicd-write"
  kubernetes_namespace = "app"
  cluster_role_binding = false
  ttl                  = "10m"
}

# Get IP address of Kubernetes API
data "env_variable" "kubernetes-service-host" {
  name = "KUBERNETES_SERVICE_HOST"
}

# Configure Kubernetes authetnication
provider "kubernetes" {
  host     = "https://${data.env_variable.kubernetes-service-host.value}"
  token    = data.vault_kubernetes_service_account_token.token.service_account_token
  insecure = true
}

