resource "kubernetes_deployment" "api" {
  metadata {
    name = "api"
    labels = {
        app = "api"
    }
  }
  spec {
    replicas = var.replicas
    selector { match_labels = { app = "api" } }
    template {
      metadata { labels = { app = "api" } }
      spec {
        container {
          name  = "api"
          image = "${var.image_repo}:${var.image_tag}"
          port  { container_port = 8080 }
          liveness_probe  {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds = 5
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds = 5
          }
          resources {
            requests = { cpu = "50m",  memory = "64Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = []
}