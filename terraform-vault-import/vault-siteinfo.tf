resource "vault_generic_secret" "siteinfo-config-add" {
  for_each = { for inst in local.import_content : inst.site_url => inst } 
  path = "${var.deploy_env}/path/to/secret/${each.key}"
#db_server,db_user_name,db_password,db_service_name
  data_json = jsonencode({ "db.port": each.value.db_port, "db.server": each.value.db_server, "db.servicename": each.value.db_service_name,"db.username": each.value.db_user_name  })
}

resource "vault_generic_secret" "siteinfo-secret-add" {
  for_each = { for inst in local.import_content : inst.site_url => inst } 
  path = "${var.deploy_env}/path/to/secret/${each.key}"

  data_json = jsonencode({ "db.password": each.value.db_password == "" ? sensitive(replace(lower(each.value.db_service_name), "_app", "")) : each.value.smoke_db_password })

}
