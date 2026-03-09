locals {

  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects      = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]

  secret_config_files = fileset("config/secretmanager", "*.yaml")
  secrets = {
    for f in local.secret_config_files :
    trimsuffix(f, ".yaml") => yamldecode(file("config/secretmanager/${f}"))
    if yamldecode(file("config/secretmanager/${f}")).deploy == true
  }

  sa_config_files      = fileset("config/sa", "*.yaml")
  sa_objects           = [for f in local.sa_config_files : yamldecode(file("config/sa/${f}"))]
  all_service_accounts = flatten([for obj in local.sa_objects : obj.service_accounts])
  sa_map               = { for sa in local.all_service_accounts : sa.account_id => sa if sa.deploy == true }

  sa_iam_bindings = {
    for pair in flatten([
      for sa in local.all_service_accounts : [
        for role in sa.roles : {
          key        = "${sa.account_id}__${replace(role, "/", "_")}"
          account_id = sa.account_id
          role       = role
        }
      ] if sa.deploy == true
    ]) : pair.key => pair
  }
}


module "project-factory" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//project-factory?ref=main"
  project_objects = local.project_objects
}

module "serviceaccount" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//service-account?ref=main"
  project_objects = local.project_objects
  sa_objects      = local.sa_objects
}

module "secretmanager" {
  source  = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//secretmanager?ref=main"
  secrets = local.secrets
}

