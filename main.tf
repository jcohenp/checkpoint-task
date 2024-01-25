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

resource "kubernetes_deployment" "processing_requests" {
  metadata {
    name      = "processingrequests"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "processingrequests"
      }
    }
    template {
      metadata {
        labels = {
          app = "processingrequests"
        }
      }
      spec {
        container {
          image = "jcohenp/checkpoint-processing_requests"
          name  = "processingrequests"
          port {
            container_port = 5001
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "processing_requests_svc" {
  metadata {
    name      = "processingrequestssvc"
  }
  spec {
    selector = {
      app = kubernetes_deployment.processing_requests.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 5001
      target_port = 5001
    }
  }
}

resource "kubernetes_deployment" "messages_broker" {
  metadata {
    name      = "messagesbroker"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "messagesbroker"
      }
    }
    template {
      metadata {
        labels = {
          app = "messagesbroker"
        }
      }
      spec {
        container {
          image = "jcohenp/checkpoint-messages_broker"
          name  = "messagebroker"
        }
      }
    }
  }
}
