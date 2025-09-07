terraform {
  required_version = ">= 1.6.0"
  required_providers {
    kind       = { source = "tehcyx/kind", version = "~> 0.5" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13" }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "kind-tf-kind"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "kind-tf-kind"
  }
}
