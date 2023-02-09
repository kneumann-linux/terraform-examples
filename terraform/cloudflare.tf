variable "cloudflare_domains" {
  type = map(string)
  default = {
    some-url-com = "zone-id-here"
  }

}


# Create a record
resource "cloudflare_record" "cloudflare_record" {
  for_each = { for k, v in local.cluster_sites_list : k => v if lookup(var.cloudflare_domains,replace(v.domain,".","-"),"NA") != "NA" }
#  length( var.cloudflare_domains[replace(v.domain,".","-")]) > 0 }
  zone_id = var.cloudflare_domains[replace(each.value.domain,".","-")]
  name    = each.value.site
  value   = "IP HERE"
  type    = "A"
  proxied = true
}