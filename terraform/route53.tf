variable "aws_route53_domains" {
  type = map(string)
  default = {
    mynet-chef-com = "Z1V70RCA4LQHPH"
    net-chef-com  = "Z3LEKJZQPSZ9XZ"
    ct-teamworx-com = "Z2MNND4K3CFW9Z"
  }

}


# Create a record
resource "aws_route53_record" "aws_route53_record" {
  for_each = { for k, v in local.cluster_sites_list : k => v if lookup(var.aws_route53_domains,replace(v.domain,".","-"),"NA") != "NA" }
#  length( var.aws_route53_domains[replace(v.domain,".","-")]) > 0 }
  zone_id = var.aws_route53_domains[replace(each.value.domain,".","-")]
  name    = each.value.site
  type    = "CNAME"
  ttl     = "300"
  records = ["${each.value.site}.cdn.cloudflare.net"]
}

resource "aws_route53_record" "aws_route53_record_dev" {
  for_each =  var.deploy_env == "dev" && var.create_mynetchef_urls ? { for k, v in local.cluster_sites_list : k => v } : {}
#  for_each = { for k, v in local.cluster_sites_list : k => v if lookup(var.aws_route53_domains,replace(v.domain,".","-"),"NA") != "NA" }
#  length( var.aws_route53_domains[replace(v.domain,".","-")]) > 0 }
  zone_id = var.aws_route53_domains["mynet-chef-com"]
  name    = "${replace(split(".", each.value.site)[0],"-em","") }-${lower(each.value.ct_app_sub_type)}.mynet-chef.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["${replace(split(".", each.value.site)[0],"-em","") }-${lower(each.value.ct_app_sub_type)}.mynet-chef.com.cdn.cloudflare.net"]
}

# mynet-chef.com Z1V70RCA4LQHPH
# net-chef.com Z3LEKJZQPSZ9XZ
# ct-teamworx.com Z2MNND4K3CFW9Z
