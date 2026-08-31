locals {
  project_name = data.google_projects.env_project.projects[0].project_id
}

data "google_projects" "env_project" {
  filter = "lifecycleState:ACTIVE labels.environment=${var.workspace} parent.type:folder parent.id:${var.gcp_folder_id}"
}

/*Trigger for repo level invocation*/
resource "google_cloudbuild_trigger" "trigger" {
 project         = local.project_name
 service_account = "projects/${local.project_name}/serviceAccounts/${local.project_name}@appspot.gserviceaccount.com"

 name = var.appengine_service_name

  github {
    name  = var.github_repository_name # Note: REPO must be connected first! Go to triggers -> Manage Repositories -> Ensure Global Region is Selected and then click on Connect Repository. DO NOT create a sample trigger!
    owner = var.github_org_name

    push {
      branch       = var.github_vcs_branch_regex
      invert_regex = false
    }
  }
  source_to_build {
    uri       = var.uri
    ref       = var.github_vcs_branch_regex
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = var.trigger_yaml_name
    uri       = var.uri
    revision  = var.github_vcs_branch_regex
    repo_type = "GITHUB"
  }
  substitutions = { for k, v in local.all_vars : "_${k}" => v }


  // If this is set on a build, it will become pending when it is run, 
  // and will need to be explicitly approved to start.
  approval_config {
    approval_required = contains(var.envs_requiring_build_approval, var.workspace) ? true : false
  }
  
}
