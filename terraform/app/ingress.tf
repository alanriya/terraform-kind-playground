resource "kubernetes_ingress_v1" "api" {
  metadata {
    name = "api-ing"
    # Removed rewrite-target annotation
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      # host removed to match all hosts
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "api-svc" # Explicitly set service name
              port { number = 8080 }
            }
          }
        }
      }
    }
  }
}
