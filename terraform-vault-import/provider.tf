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

#terraform init -no-color -backend-config=password=${vault_token} -backend-config=username=${env.tf_workspace} -backend-config provider-vars/${deploy_env}-backend.tfvars -plugin-dir=/home/jenkins/terraform-plugins/linux_amd64
terraform {
  backend "http" {
  #update end path "test-backend" to project name

  # address = "https://tfsecurebackend-dev.some.domain.com/terraform_state/vault-import"
  # lock_address = "https://tfsecurebackend-dev.some.domain.com/terraform_lock/vault-import"
  # lock_method = "PUT"
  # unlock_address = "https://tfsecurebackend-dev.some.domain.com/terraform_lock/vault-import"
  # unlock_method = "DELETE"


  # Vault PW, should be passed as
  # -backend-config=password=s.MnbIo7dcO8id4b5VIYBr 
  #password = "s.MnbIo13378id4b5VIYBr" #<--- note: this is fake
  # OR --  export TF_HTTP_PASSWORD=s.MnbIo7dcO81337id4b5VIYBr
  # pseudo workspace, should be passed as
  # -backend-config=username=testdemo 
 
  
  }
}

