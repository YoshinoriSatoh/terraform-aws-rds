/**
 * # Terraform AWS RDS module
 *
 * RDSインスタンス及び付随リソースを作成します。
 */
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_db_option_group" "main" {
  name                     = var.identifier
  option_group_description = var.identifier
  engine_name              = var.engine.name
  major_engine_version     = var.engine.version
  tags = {
    Name = var.identifier
  }

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY"
    }
    option_settings {
      name  = "SERVER_AUDIT_QUERY_LOG_LIMIT"
      value = "20480"
    }
  }
}

resource "aws_security_group" "main" {
  name        = "rds-${var.identifier}"
  description = "rds-${var.identifier}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "main" {
  for_each = {
    for key, ingress in var.ingresses : key => {
      description       = ingress.description
      security_group_id = ingress.security_group_id
    }
  }
  description              = each.value.description
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value.id
  security_group_id        = aws_security_group.main.id
}

resource "aws_db_instance" "main" {
  name                                = var.dbname
  engine                              = var.engine.name
  engine_version                      = var.engine_version
  multi_az                            = var.multi_az
  parameter_group_name                = var.db_parameter_group_name
  db_subnet_group_name                = var.db_subnet_grounp_name
  option_group_name                   = aws_db_option_group.main.name
  instance_class                      = var.instance_class
  identifier                          = var.identifier
  storage_type                        = var.storage_type
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  port                                = var.port
  vpc_security_group_ids              = [aws_security_group.main.id]
  username                            = var.username
  password                            = aws_ssm_parameter.root_password.value
  iam_database_authentication_enabled = true
  performance_insights_enabled        = var.performance_insights_enabled
  storage_encrypted                   = var.storage_encrypted
  delete_automated_backups            = var.in_development ? true : false
  deletion_protection                 = var.in_development ? false : true
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  maintenance_window                  = var.maintenance_window
  monitoring_interval                 = var.monitoring_interval
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot                 = var.in_development
  final_snapshot_identifier           = var.in_development ? null : "${var.tf.fullname}-${formatdate("YYYY-mm-DD", timestamp())}"
  copy_tags_to_snapshot               = true
}

resource "random_password" "root" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "root_password" {
  name   = "${var.parameter_srote_path_prefix}/root_password"
  type   = "SecureString"
  key_id = var.parameter_srote_kms_key_id != "" ? var.parameter_srote_kms_key_id : null
  value  = random_password.root.result
}

# # Cloudwatch Metric Alerms
# resource "aws_cloudwatch_metric_alarm" "main_cpu_utilization_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_cpu_utilization_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.cpu_utilization
#   alarm_description   = "Average database CPU utilization over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_cpu_credit_balance_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_cpu_credit_balance_low"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "CPUCreditBalance"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.cpu_credit_balance
#   alarm_description   = "Average database cpu credit balance over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_free_storage_space_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_free_storage_space_threshold"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "FreeStorageSpace"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.free_storage_space
#   alarm_description   = "Average database free storage space over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_freeable_memory_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_freeable_memory_low"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "FreeableMemory"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.freeable_memory
#   alarm_description   = "Average database freeable memory over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_swap_usage_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_swap_usage_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "SwapUsage"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.swap_usage
#   alarm_description   = "Average database swap usage over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_connections_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_connections_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "DatabaseConnections"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.connections
#   alarm_description   = "Average database connections over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_burst_balance_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_burst_balance_low"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "BurstBalance"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.burst_balance
#   alarm_description   = "Average burst balance over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_ebs_io_balance_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_ebs_io_balance_low"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "EBSIOBalance"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.ebs_io_balance
#   alarm_description   = "Average ebs io balance over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_ebs_byte_balance_low" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_ebs_byte_balance_low"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "EBSByteBalance"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.ebs_byte_balance
#   alarm_description   = "Average ebs byte balance over last 5 minutes low"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_read_iops_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_read_iops_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "ReadIOPS"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.read_iops
#   alarm_description   = "Average read_iops over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
#   tags = var.tf.tags
# }

# resource "aws_cloudwatch_metric_alarm" "main_write_iops_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_write_iops_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "WriteIOPS"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.write_iops
#   alarm_description   = "Average write_iops over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_read_throughtput_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_read_throughtput_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "ReadThroughput"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.read_throughtput
#   alarm_description   = "Average read_throughtput over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_write_throughtput_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_write_throughtput_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "WriteThroughput"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.write_throughtput
#   alarm_description   = "Average write_throughtput over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_network_receive_throughtput_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_network_receive_throughtput_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "NetworkReceiveThroughput"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.network_receive_throughtput
#   alarm_description   = "Average network receive throughtput over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "main_network_transmit_throughtput_high" {
#   alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.main.name}_network_transmit_throughtput_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "5"
#   datapoints_to_alarm = "3"
#   metric_name         = "NetworkTransmitThroughput"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = var.alarm.thresholds.network_transmit_throughtput
#   alarm_description   = "Average network transmit throughtput over last 5 minutes high"
#   alarm_actions       = [var.alarm.sns_topic_arn]
#   ok_actions          = [var.alarm.sns_topic_arn]
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }