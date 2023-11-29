variable "aws_region" {
    default = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type       = string
  default = "10.0.0.0/16"
}

variable "settings" {
    description = "configuration settings"
    type        = map(any)
    default = {
        "database" = {
            allocated_storage = 20
            engine = "mysql"
            engine_version = "5.7"
            instance_class = "db.t2.micro"
            db_name = "projeto_db"
            skip_final_snapshot = true
            storage_type = "gp2"
            publicly_accessible = false
            backup_retention_period = 7 
            backup_window = "02:00-03:00"
            maintenance_window = "Sun:03:30-Sun:04:30"
            multi_az = true
            parameter_group_name = "default.mysql5.7"
        },
        "web_app" = {
            instance_type = "t2.micro"
        }
    }
}

variable "node_size" {
    description = "number of nodes"
    type        = number
    default     = 3
}

variable "locust_plan_filename" {
    description = "locust plan filename"
    type        = string
    default     = "locust.py"
}

