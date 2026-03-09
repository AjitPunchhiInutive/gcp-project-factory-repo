locals {

  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects      = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]

  secret_config_files = fileset("config/secretmanager", "*.yaml")
  secrets = {
    for f in local.secret_config_files :
    trimsuffix(f, ".yaml") => yamldecode(file("config/secretmanager/${f}"))
    if yamldecode(file("config/secretmanager/${f}")).deploy == true
  }

  sa_config_files      = fileset("config/serviceaccount", "*.yaml")
  config         = [for f in local.sa_config_files : yamldecode(file("config/serviceaccount/${f}"))]
  all_service_accounts = flatten([for obj in local.config: obj.service_accounts])
  sa_map = { for k, sa in var.config.service_accounts : k => sa }


}


module "project-factory" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//project-factory?ref=main"
  project_objects = local.project_objects
}

module "serviceaccount" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//service-account?ref=main"
  config          = local.config
}

module "secretmanager" {
  source  = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//secretmanager?ref=main"
  secrets = local.secrets
}

