locals {

  project_config_files = fileset("config/project-factory", "*.yaml")
  project_objects      = [for f in local.project_config_files : yamldecode(file("config/project-factory/${f}"))]

  secret_config_files = fileset("config/secretmanager", "*.yaml")
  secrets = {
    for f in local.secret_config_files :
    trimsuffix(f, ".yaml") => yamldecode(file("config/secretmanager/${f}"))
    if yamldecode(file("config/secretmanager/${f}")).deploy == true
  }

  # ─── Read & decode all YAML files from config directory ──────────────────
  sa_config_files = fileset("config/serviceaccount", "*.yaml")
  config_objects  = [for f in local.sa_config_files : yamldecode(file("config/serviceaccount/${f}"))]

  # ─── Build merged config — YAML values override defaults ─────────────────
  # Passes the full config object expected by var.config
  config = {
    project_id                = local.config_objects[0].project_id
    region                    = try(local.config_objects[0].region, "us-central1")
    environment               = try(local.config_objects[0].environment, "dev")
    secret_manager_project_id = try(local.config_objects[0].secret_manager_project_id, "")
    key_rotation_days         = try(local.config_objects[0].key_rotation_days, 90)
    labels                    = try(local.config_objects[0].labels, {})
    service_accounts          = local.sa_map
  }

  # ─── FIX: var.config.service_accounts is map(object) — NO deploy field ───
  # Iterate directly using map key (k) — no deploy filter needed
  sa_map = {
    for k, sa in var.config.service_accounts : k => {
      account_id   = sa.account_id
      display_name = sa.display_name
      description  = sa.description
      iam_roles    = sa.iam_roles
      create_key   = sa.create_key
      secret_id    = try(sa.secret_id, null)
    }
  }

  # ─── SAs that need a key (create_key = true) ─────────────────────────────
  sa_with_key = {
    for k, sa in local.sa_map : k => sa
    if sa.create_key == true
  }

  # ─── SAs that do NOT need a key ──────────────────────────────────────────
  sa_without_key = {
    for k, sa in local.sa_map : k => sa
    if sa.create_key == false
  }

  # ─── Flatten SA + IAM roles for google_project_iam_member for_each ───────
  # FIX: field is iam_roles (not roles) — matches variables.tf
  # Key format: "<map_key>__<role>"
  sa_iam_bindings = {
    for pair in flatten([
      for k, sa in local.sa_map : [
        for role in sa.iam_roles : {
          key        = "${k}__${replace(role, "/", "_")}"
          map_key    = k
          role       = role
          project_id = var.config.project_id
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

