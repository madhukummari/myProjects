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

###################################### Phase 2 : ec2 and volume creation ######################################
resource "aws_instance" "web" {
  ami           = "ami-020cba7c55df1f615" # Amazon Linux 2
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name      = "keypair2025" # Replace with your key pair name

  user_data = <<-EOF
              #!/bin/bash
              mkfs -t ext4 /dev/xvdbb
              mkdir /data
              mount /dev/xvdbb /data
              echo "Mounted volume and created directory" > /data/setup.txt
              EOF

  tags = {
    Name   = "Backup-Instance"
    Backup = "true"
  }
}

resource "aws_ebs_volume" "additional_volume" {
  availability_zone = aws_instance.web.availability_zone
  size              = 8 # Size in GB

  tags = {
    Name   = "Backup-Volume"
    Backup = "true"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.additional_volume.id
  instance_id = aws_instance.web.id
}

############################################ Phase 3 : event trigger restoration ######################################
resource "aws_cloudwatch_event_target" "log_target" {
  rule      = aws_cloudwatch_event_rule.snapshot_complete.name
  target_id = "send-to-cloudwatch"
  arn       = aws_cloudwatch_log_group.snapshot_event_log_group.arn
  role_arn  = aws_iam_role.eventbridge_logs_role.arn
}

resource "aws_iam_role" "eventbridge_logs_role" {
  name = "eventbridge-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_logs_policy" {
  name = "eventbridge-logs-policy"
  role = aws_iam_role.eventbridge_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ],
      Resource = "${aws_cloudwatch_log_group.snapshot_event_log_group.arn}:*"
    }]
  })
}


resource "aws_cloudwatch_event_rule" "snapshot_complete" {
  name        = "snapshot-complete-rule"
  description = "Triggers when an AWS Backup job completes for our vault"

  event_pattern = jsonencode({
    source      = ["aws.backup"],
    "detail-type": ["Backup Job State Change"],
    detail      = {
      state            = ["COMPLETED"],
      backupVaultName  = [aws_backup_vault.main.name],
      resourceType     = ["EBS"]
    }
  })
}
