locals {
  sorted_list_sites = {for inst in local.import_content : inst.cluster_name => inst.site_url ... }
  sites_list = {for cluster_name in local.cluster_list : cluster_name => zipmap(local.sorted_list_sites[cluster_name], [for i in range(length(local.sorted_list_sites[cluster_name])) : "1"]  ) ... }

  ## Get list of smoke sites if they exist
  smoke_sorted_list_sites = {for inst in local.import_content : inst.cluster_name => try(inst.smoke_site_url,"") ... }
  smoke_sites_list = try({for cluster_name in local.cluster_list : cluster_name => zipmap(compact(local.smoke_sorted_list_sites[cluster_name]), [for i in range(length(local.smoke_sorted_list_sites[cluster_name])) : "1"]  ) ... }, null)
}


output "sites_list" {
  value = local.sites_list
  
}

output "smoke_sites_list" {
  value = try(local.smoke_sites_list,"NA")
  
}

#- name: "Create cluster siteinfo config /siteinfo/{{ cluster_name }}"
resource "vault_generic_secret" "siteslist-add" {
  for_each = local.sites_list
  path = "${var.deploy_env}/path/to/secret/${each.key}"

## A little dumb but each key has multiple copies of the same list, so I just grab the first one. 
## It's because I'm looping on the whole csv, not the sorted_list_sites, but I couldn't get the key back out to loop over that ...

## Try to merge with smoke lists if they exist.
  data_json = jsonencode( try(merge(each.value[0], local.smoke_sites_list[each.key][0] ), each.value[0])  )
}