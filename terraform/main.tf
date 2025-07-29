resource "aws_backup_vault" "main" {
  name = "my-backup-terraform"
}

resource "aws_backup_plan" "main" {
  name = "ec2-ebs-backup-plan"

  rule {
    rule_name         = "6-hour-snapshot"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 */6 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "tag_selection" {
  iam_role_arn = "arn:aws:iam::027694487790:role/service-role/AWSBackupDefaultServiceRole"
  name         = "backup-tagged-resources"
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
