data "aws_eks_cluster_auth" "main" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                    = module.eks.cluster_endpoint
  cluster_ca_certificate  = base64decode(module.eks.cluster_certificate_authority_data)
  token                   = data.aws_eks_cluster_auth.main.token
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "eks-${random_string.suffix.result}"
  lb_name = kubernetes_service.processing_requests_svc.status.0.load_balancer.0.ingress.0.hostname
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
    replicas = 1
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
    replicas = 1
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
          name  = "messagesbroker"
        }
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.custom_nodegroup_policy_node1,
    aws_iam_role_policy_attachment.custom_nodegroup_policy_node2,
    aws_iam_role_policy_attachment.sqs_publish_policy_attachment_node1,
    aws_iam_role_policy_attachment.sqs_publish_policy_attachment_node2
  ]
}
