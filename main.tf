provider "kubernetes" {
  host                    = module.eks.cluster_endpoint
  cluster_ca_certificate  = base64decode(module.eks.cluster_certificate_authority_data)
  config_path    = "~/.kube/config"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "kubernetes_deployment" "flaskapp" {
  metadata {
    name      = "flaskapp"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "flaskapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "flaskapp"
        }
      }
      spec {
        container {
          image = "jcohenp/checkpoint-exam"
          name  = "flaskapp"
          port {
            container_port = 5001
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "flaskapp_svc" {
  metadata {
    name      = "flaskappsvc"
  }
  spec {
    selector = {
      app = kubernetes_deployment.flaskapp.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 5001
      target_port = 5001
    }
  }
}