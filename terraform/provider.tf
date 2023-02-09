variable "deploy_env" {
  type = string
  default = "dev"
}

variable "login_approle_role_id" {
  type = string
}

variable "login_approle_secret_id" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "create_mynetchef_urls" {
  type = bool
  default = true
}

provider "kubernetes" {
  config_path    = "../.kube/config"
  config_context = "kubernetes-admin@kubernetes"
}


provider "vault" {
 address = "https://vault-${var.deploy_env}.some.domain.com:8200/"
 skip_tls_verify = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}

terraform {
  required_providers {
      cloudflare = {
        source = "cloudflare/cloudflare"
        version = "~> 3.0"
      }
      site24x7 = {
        source  = "site24x7/site24x7"
        version = "~> 1.0.0"
      }
      aws = {
        version = "4.22.0"
      }

    }


  backend "consul" {}

}

provider "cloudflare" {
  email   = "kneumann@crunchtime.com"
  api_key = var.cloudflare_api_token
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


variable "dns_ip" {
  description = "IP address of Master DNS-Server"
  default = ""
}
variable "dns_key" {
  description = "name of the DNS-Key to user"
  ## Required . at the end of the key name
  default = ""
}
variable "dns_key_secret" {
  description = "base 64 encoded string"
  default = ""
}


provider "dns" {
  update {
    server        = "${var.dns_ip}"
    key_name      = "${var.dns_key}"
    key_algorithm = "hmac-md5"
    key_secret    = "${var.dns_key_secret}"
  }
}