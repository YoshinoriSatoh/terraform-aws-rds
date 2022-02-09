variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "in_development" {
  description = "開発モード. destroy時やapplyの変更内容によっては、RDSインスタンス及びバックアップ群が強制削除されます."
  type        = bool
  default     = false
}

variable "engine" {
  type = object({
    name    = string
    version = string
  })
  default = {
    name    = "mysql"
    version = "8.0"
  }
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_grounp_name" {
  type = string
}

variable "db_parameter_group_name" {
  description = "パラメータグループはDBインスタンス個別に作成することを推奨."
  type        = string
}

variable "parameter_srote_path_prefix" {
  type = string
}

variable "parameter_srote_kms_key_id" {
  type    = string
  default = ""
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "identifier" {
  description = "DBインスタンス識別子. tf.fullname のような環境名を含んだ名前を推奨"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "8.0.25"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "port" {
  type    = number
  default = 3306
}

variable "dbname" {
  type    = string
  default = "main"
}

variable "storage_type" {
  type    = string
  default = "gp2"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 1000
}

variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}

variable "username" {
  type    = string
  default = "root"
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "backup_window" {
  type    = string
  default = "20:00-20:30"
}

variable "maintenance_window" {
  type    = string
  default = "sun:21:00-sun:21:30"
}

variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["audit", "error", "slowquery"]
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "ingresses" {
  type = list(object({
    description       = string
    security_group_id = string
  }))
  default = []
}

# variable "alarm" {
#   type = object({
#     thresholds = object({
#       cpu_utilization              = string
#       cpu_credit_balance           = string
#       free_storage_space           = string
#       freeable_memory              = string
#       swap_usage                   = string
#       connections                  = string
#       burst_balance                = string
#       ebs_io_balance               = string
#       ebs_byte_balance             = string
#       read_iops                    = string
#       write_iops                   = string
#       read_throughtput             = string
#       write_throughtput            = string
#       network_receive_throughtput  = string
#       network_transmit_throughtput = string
#     })
#     # sns_topic_arn = string
#   })
# }
