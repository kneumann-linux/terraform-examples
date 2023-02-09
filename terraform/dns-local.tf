
resource "dns_cname_record" "local-dns-dynamic" {
for_each = var.deploy_env != "perf" ? { for k, v in local.cluster_sites_list : k => v if lookup(var.aws_route53_domains,replace(v.domain,".","-"),"NA") == "NA" } : {}
  zone  = "${each.value.domain}."
  name  = split(".", each.value.site)[0]
  cname = "k8-lb-vip.${var.deploy_env}.some.domain.com"
  ttl   = 300
}