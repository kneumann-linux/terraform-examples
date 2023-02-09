

data "vault_generic_secret" "cluster_secrets" {
  for_each = var.clusters-list

  path = "${var.deploy_env}/path/to/key/${each.key}"
}

locals {
    cluster_settings = data.vault_generic_secret.cluster_secrets
    app_name_map = {
       EM="enterprise-manager",
       NC="net-chef",
       TWX="teamworx"
    }

    volume_mount_map = {
      CES = {
             crunchtime-conf = "path here",
             vp-conf = "path here",
             crunchtime-conf-s-sites = "path here"
           },
      TWX = {
             crunchtime-conf = "path here",
             crunchtime-conf-s-sites = "path here"
           }
    }

}


resource "kubernetes_service_v1" "deployment-service" {
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    kubernetes_deployment_v1.deployment-pods,
  ]

  for_each = local.cluster_settings

    metadata {
      name = "${each.key}"
    }
    spec {
      selector = {
        cluster = "${each.key}"
      }
      port {
        name = "${lower(nonsensitive(each.value.data.ct_app))}-port-admin"
        port = 8081
        protocol = "TCP"
        target_port = 8081
      }
      port {
        name = "${lower(nonsensitive(each.value.data.ct_app))}-port-app"
        port = 8080
        protocol = "TCP"
        target_port = 8080
      }

      type = "ClusterIP"
    }
  }


resource "kubernetes_deployment_v1" "deployment-pods" {
lifecycle {
  create_before_destroy = true
}

  for_each = local.cluster_settings

  metadata {
    name = "${each.key}"
    labels = {
      cluster = "${each.key}"
      app_version = "${nonsensitive(each.value.data.ct_app_ver)}"
      client = "${lower(nonsensitive(each.value.data.client_namespace))}"
    }
  }

  spec {
    replicas = nonsensitive(each.value.data.replicas)

    selector {
      match_labels = {
        cluster = "${each.key}"
      }
    }

    template {
      metadata {
        labels = {
          cluster = "${each.key}"
          app_version = "${nonsensitive(each.value.data.ct_app_ver)}"
          client = "${lower(nonsensitive(each.value.data.client_namespace))}"
        }
      }
      spec {
        security_context {
           fs_group = 500
        }
        affinity {
          pod_anti_affinity {
              preferred_during_scheduling_ignored_during_execution {
                weight = 100

                pod_affinity_term {
                  label_selector {
                    match_expressions {
                      key      = "cluster"
                      operator = "In"
                      values   = ["${each.key}"]
                    }
                  }
                  topology_key = "topology.kubernetes.io/zone"
                }
              }
          }
        }
        image_pull_secrets {
           name = "dhub-login-${var.deploy_env}"
        }


        dynamic "volume" {
          for_each = local.volume_mount_map[each.value.data.ct_app]
          content {
            name = "${volume.key}"
            empty_dir {}
          }
        }

        #### IF glusterfs is enabled in vault entry
        dynamic "volume" {
          for_each = try(nonsensitive(each.value.data.enable_glusterfs),false) ? [1] : []
          content {
              name = "glusterfsvol"
              glusterfs {
                endpoints_name = "glusterfs-cluster"
                path = "gv0"
                read_only = false
              }
          }
        }


        init_container {
            image = "path/to/crunchtime-init:${nonsensitive(lookup(each.value.data, "ct_init_ver", "latest"))}"
            name  = "${each.key}-init"
            env {
               name = "cluster_name"
               value = "${each.key}"
            }
            env {
                name = "deploy_env"
                value = var.deploy_env
           }
           env {
              name = "ct_app"
              value = nonsensitive(each.value.data.ct_app)
           }
            env {
               name = "ct_app_sub_type"
               value = nonsensitive(each.value.data.ct_app_sub_type)
            }
            env {
                name = "ct_app_ver"
                value = nonsensitive(each.value.data.ct_app_ver)
           }
           env {
              name = "log4j2_override_file"
              value = nonsensitive(lookup(each.value.data, "log4j2_override_file", ""))
           }
           env {
              name = "hcv_role_id"
              value_from {
                 secret_key_ref {
                     name = "hcv-vault"
                     key = "username"
                }
              }
           }
           env {
              name = "hcv_secret_id"
              value_from {
                 secret_key_ref {
                     name = "hcv-vault"
                     key = "password"
                }
              }
           }


           dynamic "volume_mount" {
             for_each = local.volume_mount_map[each.value.data.ct_app]
             content {
               name = "${volume_mount.key}"
               mount_path = "${volume_mount.value}"
             }
           }

        }
        container {
            image = "path/to/crunchtime-${lower(each.value.data.ct_app)}:${each.value.data.ct_app_ver}"
            name  = "${each.key}"
            image_pull_policy = "Always"

            env {
                name = "ENV"
                value = var.deploy_env
           }
           env {
              name = "APP"
              value = nonsensitive(each.value.data.ct_app)
           }
            env {
               name = "META"
               value = nonsensitive(lookup(each.value.data, "META", 375))
            }
            env {
               name = "MIN_META"
               value = nonsensitive(lookup(each.value.data, "MIN_META", 70))
            }
            env {
               name = "MAX_META"
               value = nonsensitive(lookup(each.value.data, "MAX_META", 1024))
            }
            env {
               name = "XMX"
               value = nonsensitive(lookup(each.value.data, "XMX", 3096))
            }
            env {
               name = "XMS"
               value = nonsensitive(lookup(each.value.data, "XMS", 3096))
            }
            env {
               name = "MEM_OPTS_EXTRA"
               value = nonsensitive(lookup(each.value.data, "MEM_OPTS_EXTRA", ""))
            }

            port {
              container_port = "8080"
              name = "app"
              protocol = "TCP"
            }
            port {
              container_port = "8081"
              name =  "admin"
              protocol = "TCP"
            }
            port {
              container_port = "8280"
              name =  "jmxrmi"
              protocol = "TCP"
            }
            port {
              container_port = "8281"
              name =  "jmxmp"
              protocol = "TCP"
            }
            port {
              container_port = "8000"
              name =  "jmxdebug"
              protocol = "TCP"
            }
           dynamic "volume_mount" {
             for_each = local.volume_mount_map[each.value.data.ct_app]
             content {
               name = "${volume_mount.key}"
               mount_path = "${volume_mount.value}"
             }
           }


            dynamic "volume_mount" {
              for_each = try(nonsensitive(each.value.data.enable_glusterfs),false) ? [1] : []
              content {
                name = "glusterfsvol"
                mount_path = "/crunchtime/teamworx/platform/uploads"
              }
            }

            resources {
              limits = {
                cpu    = "4"
                memory = "8Gi"
              }
              requests = {
                cpu    = "4"
                memory = "8Gi"
              }
            }

            readiness_probe {
              http_get {
                path = "${each.value.data.ct_app == "CES" ? "/server-check" : "/server-admin"}"
                port = "app"

              }

              failure_threshold = 5
              period_seconds    = 5
            }

            startup_probe {
              http_get {
                path = "${each.value.data.ct_app == "CES" ? "/server-check" : "/server-admin"}"
                port = "app"

              }

              failure_threshold = 30
              period_seconds    = 10
              initial_delay_seconds = 30
            }

        }
      }
    }
  }
}
