variable "site24x7_oauth2_client_id" {
  type = string
  default = ""
}

variable "site24x7_oauth2_client_secret" {
  type = string
  default = ""
}

variable "site24x7_oauth2_refresh_token" {
  type = string
  default =""
}

provider "site24x7" {
  oauth2_client_id = var.site24x7_oauth2_client_id
  oauth2_client_secret = var.site24x7_oauth2_client_secret
  oauth2_refresh_token = var.site24x7_oauth2_refresh_token
  data_center = "US"
}

locals {
  site24x7_map = {
    APP_NAME = {
      matching_keyword_value="matching_keyword_value",
      unmatching_keyword_value="unmatching_keyword_value list",
      monitor_groups = "monitor_groups",
      timeout = 30 ,
      unmatching_keyword_severity = 0
      tag_id = "tag_id"
    }
  }
  
}

## only if prod

resource "site24x7_website_monitor" "site24x7_web_monitor" {
  ## loop external urls
  for_each = var.deploy_env == "prod" ? { for k, v in local.cluster_sites_list : k => v if lookup(var.aws_route53_domains,replace(v.domain,".","-"),"NA") != "NA" } : {}


  #main 
  display_name = join("-",[replace(split(".", each.value.site)[0],"-em",""), each.value.ct_app_sub_type])
  
  #"${split(\".\", each.value.site)[0]}-${each.value.ct_app_sub_type}"
  website = "https://${each.value.site}"
  check_frequency = "1"
  location_profile_name = "Ct-Locales"
  #Monitoring Locations  

  
  #Content checks\
  ##changes per app
  matching_keyword_value="${local.site24x7_map[each.value.ct_app_sub_type].matching_keyword_value}"
  #Trouble
  matching_keyword_severity  = 2 
  
  ## changes per app <--- need to test mult
  unmatching_keyword_value="${local.site24x7_map[each.value.ct_app_sub_type].unmatching_keyword_value}"
  #Down
  unmatching_keyword_severity = "${local.site24x7_map[each.value.ct_app_sub_type].unmatching_keyword_severity}"
  
  match_case = false
  use_name_server = false
  
  # HTTP Config
  #GET
  http_method = "G" 
  # Basic/NTLM
  auth_method = "B" 
  ssl_protocol = "Auto"
  #HTTP/1.1
  http_protocol = "H1.1" 
  use_alpn = true
  
  #Advanced Config
  timeout = "${local.site24x7_map[each.value.ct_app_sub_type].timeout}"
  use_ipv6 = false
  
  #Net Chef or TeamWorx
  monitor_groups = ["${local.site24x7_map[each.value.ct_app_sub_type].monitor_groups}",]
  
  #Config Profiles
  #ct-avail
  threshold_profile_id = "threshold_profile_id"  

  
  #Alert Settings
  user_group_names = [
    "user_group_names",
  ]
  notification_profile_name = "Default Notification"
  
  #Third Party Integrations
  third_party_service_ids = [
   "opsgenie_id"
  ]
 
  tag_ids = ["${local.site24x7_map[each.value.ct_app_sub_type].tag_id}"]
}
