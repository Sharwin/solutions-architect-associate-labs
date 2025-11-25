terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_amplify_app" "lab_app" {
  name       = "techcorp-landing-page"


  # Build settings are not strictly needed for manual deployment but good to have empty
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        build:
          commands: []
      artifacts:
        baseDirectory: /
        files:
          - '**/*'
      cache:
        paths: []
  EOT
  
  enable_branch_auto_build = false
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.lab_app.id
  branch_name = "main"
  
  framework = "Web"
  stage     = "PRODUCTION"
}

output "amplify_app_id" {
  value = aws_amplify_app.lab_app.id
}

output "amplify_branch_name" {
  value = aws_amplify_branch.main.branch_name
}

output "amplify_default_domain" {
  value = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.lab_app.default_domain}"
}

output "aws_region" {
  value = "us-east-1"
}
