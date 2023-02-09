variable "clusters-types" {
  type = set(string)
  default = ["ces","twx","nc","em"]  #TODO: make this dynamic
}

variable "client_namespace" {
  type = string
  default = "patch-1020"
}

#- name: "Get defaults for {{ app_type }}"
data "vault_generic_secret" "cluster_defaults" {
  for_each = var.clusters-types
  path = "${var.deploy_env}/path/to/secret/${each.key}"
}

#- name: "Create cluster config {{ cluster_name }}"
resource "vault_generic_secret" "cluster-add" {
  for_each = { for inst in local.import_content : inst.cluster_name => inst ... } 
  path = "${var.deploy_env}/path/to/secret/${each.key}"

  data_json = jsonencode(merge(data.vault_generic_secret.cluster_defaults[lower(each.value[0].app_type)].data, { "ct_app_ver": each.value[0].app_version, "client_namespace": var.client_namespace }))
}