# Application secrets stored in SSM Parameter Store
# Values are initialized with "change-me" and managed manually or via CI.
# ECS task definitions reference these by ARN.

resource "aws_ssm_parameter" "rails_secret_key_base" {
  name  = "somleng.secret_key_base"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "fs_esl_password" {
  name  = "somleng.fs_esl_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "anycable_secret" {
  name  = "somleng.anycable_secret"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "rating_engine_password" {
  name  = "somleng.rating_engine_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
