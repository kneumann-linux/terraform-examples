variable "ingress-domains" {
  type = list(string)
  default = ["some-site.com"]

}

data "vault_generic_secret" "cluster_sites_secrets" {
  for_each = var.clusters-list


  path = "${var.deploy_env}/path/to/${each.key}"
}

locals {
    cluster_sites_settings = data.vault_generic_secret.cluster_sites_secrets

    client_namespaces =  distinct([for r in local.cluster_settings : "${nonsensitive(r.data.client_namespace)}" ])

    cluster_sites_list = nonsensitive(flatten([
      for cluster_id, cluster in local.cluster_settings: [
        for k, v in local.cluster_sites_settings[cluster_id].data:
          {
           cluster_name = "${cluster_id}"
           ct_app_sub_type = "${nonsensitive(local.cluster_settings[cluster_id].data.ct_app_sub_type)}" 
           site = k
           domain = join(".",slice(split(".",k),1, length(split(".",k))))
           client_namespace = "${nonsensitive(local.cluster_settings[cluster_id].data.client_namespace)}"
         }
         if v > "0"
      ]
    ]))

    map_cluster_sites_list = { for obj in local.cluster_sites_list : "${obj.client_namespace}" => obj ... }
 }


resource "kubernetes_ingress_v1" "dynamic-ingress" {
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    kubernetes_deployment_v1.deployment-pods,
  ]

  for_each = local.map_cluster_sites_list

  wait_for_load_balancer = true
  metadata {
    name = "${replace(each.key, ".", "-")}-ingress"

    annotations = {
      "kubernetes.io/ingress.class" = "nginx",
      "nginx.ingress.kubernetes.io/default-backend" = "default-http-sitemaintenance"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "100m"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout"	= "1200"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "1200"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "1200"

    }
  }

  spec {
    default_backend {
      service {
        name = "default-http-sitemaintenance"
        port {
          number = 80
        }
      }
    }


    dynamic "rule" {
        for_each = local.map_cluster_sites_list[each.key]
        content {
            host = "${rule.value.site}"
            http {
              path {
                backend {
                  service {
                    name = "${rule.value.cluster_name}"
                    port {
                      number = 8080
                    }
                  }
                }

                path = "/"
              }
            }
        }
    }

    dynamic "rule" {
      for_each =  var.deploy_env == "dev" && var.create_mynetchef_urls ? local.map_cluster_sites_list[each.key] : [] 
        content {
            host = "${replace(split(".", rule.value.site)[0],"-em","") }-${lower(rule.value.ct_app_sub_type)}.some-site.com"
            http {
              path {
                backend {
                  service {
                    name = "${rule.value.cluster_name}"
                    port {
                      number = 8080
                    }
                  }
                }

                path = "/"
              }
            }
        }
    }
     

     dynamic "tls" {
      for_each = toset(var.ingress-domains)
       content {
        secret_name = "${tls.key}2022-fullchain-cert"
        hosts = ["${tls.key}", "*.${tls.key}" ]
       }
    }
  }
}
