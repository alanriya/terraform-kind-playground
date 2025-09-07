#############################
# main.tf
#############################

# Convenience locals (used in outputs)
locals {
  base_url = "http://${var.ingress_host}/api"
}

# Load the locally built image into the kind cluster so pods can pull it
# (Assumes you built: docker build -t ${var.image_repo}:${var.image_tag} ./api)
# Safe to run repeatedly; the "|| true" keeps applies idempotent if image already exists.
resource "null_resource" "load_local_image_into_kind" {
  triggers = {
    image = "${var.image_repo}:${var.image_tag}"
  }

  provisioner "local-exec" {
    command = "kind load docker-image ${var.image_repo}:${var.image_tag} --name tf-kind || true"
  }
}

module "app" {
  source = "./app"
  
  replicas   = var.replicas
  image_repo = var.image_repo
  image_tag  = var.image_tag
  
  depends_on = [null_resource.load_local_image_into_kind, module.ingress]
}

module "ingress" {
    source = "./ingress"
}

# (Optional) You can force app resources to wait for the image load by adding
# depends_on = [ null_resource.load_local_image_into_kind ]
# inside your kubernetes_deployment "api" in app/deployment.tf.
# If you don't want that coupling, leave it as-is—the kubelet will pull whatever tag exists.

#############################
# Helpful outputs
#############################

output "ingress_endpoints" {
  description = "Ingress URLs you can curl"
  value = {
    health = "${local.base_url}/health"
    time   = "${local.base_url}/time"
    echo   = "${local.base_url}/echo"
  }
}

output "replicas" {
  description = "Current desired replica count for the API Deployment"
  value       = var.replicas
}