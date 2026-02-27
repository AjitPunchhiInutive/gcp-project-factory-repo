locals {

  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]
}

module "project-factory" {
  source          = "git@github.com:AjitPunchhiInutive/-sw-prod-udp-rds-infra-modules.git//project-factory?ref=main"
  project_objects = local.project_objects
}
