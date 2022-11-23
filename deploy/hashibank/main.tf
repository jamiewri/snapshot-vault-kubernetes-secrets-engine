resource "kubernetes_pod" "hashibank" {
  metadata {
    name      = "hashibank"
    namespace = "app"
    labels = {
      app = "hashibank"
    }
  }

  spec {
    container {
      image = "jamiewri/hashibank:0.0.3"
      name  = "hashibank"
      args  = ["-dev"]

      port {
        container_port = 8080
      }
    }
  }
}
