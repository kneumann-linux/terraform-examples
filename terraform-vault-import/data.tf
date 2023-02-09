variable "import-filename" {
  type = string
  default = "import.csv"
}

variable "import-filepath" {
  type = string
  default = "."
}


locals {
  import_content = fileexists("${var.import-filepath}/${var.import-filename}") ?   csvdecode(file("${var.import-filepath}/${var.import-filename}")) : []
  cluster_list = distinct(local.import_content.*.cluster_name)
  csv = {for inst in local.import_content : inst.cluster_name => inst ... }
}

output "cluster_list" {
  value = local.cluster_list
}
