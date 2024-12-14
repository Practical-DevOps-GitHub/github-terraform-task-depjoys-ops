terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

#########################################################

variable "owner" {
  description = "The owner of the GitHub repository"
  type        = string
}

variable "github_repository_name" {
  description = "The name GitHub repository"
  type        = string
}

variable "secret_token" {
  description = "secret token"
  type        = string
}

#########################################################

provider "github" {
  token = var.secret_token  
  owner = var.owner
}

#########################################################

#resource "github_repository" "repository" {
#  name        = var.github_repository_name
#  description = "My GitHub repository"
#  visibility  = "public"
#}

#########################################################

resource "github_repository_collaborator" "collaborator" {
  repository = var.github_repository_name
  username   = "softservedata"
  permission = "admin"
}

#########################################################

resource "github_branch" "develop" {
  repository        = var.github_repository_name
  branch            = "develop"
  source_branch     = "main"
}

#########################################################

resource "github_branch_default" "default"{
  repository = var.github_repository_name
  branch     = github_branch.develop.branch
}

#########################################################

resource "github_branch_protection" "main" {
  repository_id = var.github_repository_name
  pattern       = "main"  

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
  }

  enforce_admins = true
  required_status_checks {
    strict   = true
    contexts = []
  }
}

#########################################################

resource "github_branch_protection" "develop" {
  repository_id = var.github_repository_name
  pattern       = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  enforce_admins = true
  required_status_checks {
    strict   = true
    contexts = []
  }
}

#########################################################

resource "github_repository_file" "codeowners" {
  repository = var.github_repository_name
  file       = ".github/CODEOWNERS"
  content    = "* @softservedata"
  branch     = "main"
  commit_message = "Add CODEOWNERS file"
  overwrite_on_create = true
}

#########################################################

resource "github_repository_file" "pr_template" {
  repository = var.github_repository_name
  file       = ".github/pull_request_template.md"
  content    = <<-EOT
  ## Describe your changes

  ## Issue ticket number and link

  ## Checklist before requesting a review
  - [ ] I have performed a self-review of my code
  - [ ] If it is a core feature, I have added thorough tests
  - [ ] Do we need to implement analytics?
  - [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
  branch     = "main"
  commit_message = "Add pull request template"
}

#########################################################

resource "github_repository_deploy_key" "example_repository_deploy_key" {
  title      = "DEPLOY_KEY"
  repository = var.github_repository_name
  key        = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ0FoOlQ3hvQ8OQY+Glj+azQSmjoSdOcXgtP1JcvT3SP github-terraform-task-depjoys-ops
EOF
  read_only  = true
}

#########################################################

resource "github_repository_webhook" "discord_webhook" {
  repository = var.github_repository_name
  active     = true
  events     = ["pull_request"]

  configuration {
    url          = "https://discord.com/api/webhooks/1312353462402551858/48y-z0xYA74vngd1l3MC_GD3_OAXXZrROnI-hjtDHMZSTmDsAg0QDRbhSd0Q5EpbOc_3/github"
    content_type = "json"
  }
}

#########################################################

resource "github_actions_secret" "secret_actions_token" {
  repository       = var.github_repository_name
  secret_name      = "PAT"
  plaintext_value  = var.secret_token
}

