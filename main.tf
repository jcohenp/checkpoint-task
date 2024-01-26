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

resource "kubernetes_deployment" "jenkins_master" {
  metadata {
    name      = "jenkins-master"

    labels = {
      app = "jenkins-master"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jenkins-master"
      }
    }

    template {
      metadata {
        labels = {
          app = "jenkins-master"
        }
      }

      spec {
        volume {
          name = "jenkins-local-home"

          host_path {
            path = "/tmp"
          }
        }

        container {
          name  = "jenkins"
          image = "jcohenp/jenkins"

          port {
            container_port = 8080
          }

          port {
            container_port = 50000
          }

          volume_mount {
            mount_path = "/var/jenkins_home"
            name       = "jenkins-local-home"
          }
          security_context {
            run_as_user = 0  # 0 represents the root user
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "jenkins_service" {
  metadata {
    name      = "jenkins-service"
  }

  spec {
    selector = {
      app = "jenkins-master"
    }

    type = "LoadBalancer"

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "jcli"
      port        = 50000
      target_port = 50000
    }
  }
}


# resource "kubernetes_deployment" "jenkins" {
#   metadata {
#     name = "jenkins"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "jenkins"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "jenkins"
#         }
#       }

#       spec {
#         container {
#           name  = "jenkins"
#           image = "jenkins/jenkins:lts"

#           port {
#             container_port = 8080
#           }

#           port {
#             container_port = 50000
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "jenkins" {
#   metadata {
#     name = "jenkins"
#   }

#   spec {
#     selector = {
#       app = kubernetes_deployment.jenkins.spec[0].template[0].metadata[0].labels.app
#     }

#     port {
#       name        = "http"
#       port        = 8080
#       target_port = 8080
#     }

#     port {
#       name        = "jcli"
#       port        = 50000
#       target_port = 50000
#     }

#     type = "LoadBalancer"
#   }
# }
