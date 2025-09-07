resource "kubernetes_service" "api" {
  metadata {
    name = "api-svc"
  }
  spec {
    selector = {
      app = "api"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
