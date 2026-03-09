locals {

  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]

  
  secret_config_files = fileset("config/secretmanager", "*.yaml")
  secrets  = [for f in local.secret_config_files : yamldecode(file("config/secretmanager/${f}"))]

# sa_config_files = fileset("config/serviceaccount", "*.yaml")
  # sa_objects      = [for f in local.sa_config_files : yamldecode(file("config/serviceaccount/${f}"))]
}

module "project-factory" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//project-factory?ref=main"
  project_objects = local.project_objects
}

# module "serviceaccount" {
#   source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//serviceaccount?ref=main"
#   project_objects = local.project_objects
#   sa_objects      = local.sa_objects
# }

module "secretmanager" {
  source   = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//secretmanager?ref=main"
  secrets = local.secrets

}
