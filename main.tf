locals {

  # ─── Project Factory ──────────────────────────────────────────────────────
  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects      = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]

  # ─── Secret Manager ───────────────────────────────────────────────────────
  secret_config_files = fileset("config/secretmanager", "*.yaml")
  secrets = {
    for f in local.secret_config_files :
    trimsuffix(f, ".yaml") => yamldecode(file("config/secretmanager/${f}"))
    if yamldecode(file("config/secretmanager/${f}")).deploy == true
  }

  # ─── Service Accounts ─────────────────────────────────────────────────────
  sa_config_files = fileset("config/serviceaccount", "*.yaml")

  # Decode all YAML files into a list
  sa_config_list = [for f in local.sa_config_files : yamldecode(file("config/serviceaccount/${f}"))]

  # FIX: Extract the single object from the list using [0]
  # Module var.config expects object — NOT a tuple/list
  config = local.sa_config_list[0]

  # FIX: Iterate local.config.service_accounts — not var.config
  sa_map = {
    for k, sa in local.config.service_accounts : k => sa
  }

  # ─── Split by create_key ──────────────────────────────────────────────────
  sa_with_key = {
    for k, sa in local.sa_map : k => sa
    if sa.create_key == true
  }

  sa_without_key = {
    for k, sa in local.sa_map : k => sa
    if sa.create_key == false
  }

  # ─── Flatten SA + IAM roles for IAM binding for_each ─────────────────────
  sa_iam_bindings = {
    for pair in flatten([
      for k, sa in local.sa_map : [
        for role in sa.iam_roles : {
          key        = "${k}__${replace(role, "/", "_")}"
          map_key    = k
          role       = role
          project_id = local.config.project_id
        }
      ]
    ]) : pair.key => pair
  }
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

