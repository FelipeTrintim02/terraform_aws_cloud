terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "felipetrintimbucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
    region = var.aws_region
}

data "aws_availability_zones" "available" {
    state = "available"
}

#####
# VPC #
#####

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "felipe_vpc"
  }
}

#####
# Internet Gateway #
#####

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "felipe_igw"
    }
}

####
# Subnets #
####

resource "aws_subnet" "felipe_public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24" #32 IPs
  map_public_ip_on_launch = true          # public subnet
  availability_zone       = "us-east-1a"
}

# Creating 2nd public subnet 
resource "aws_subnet" "felipe_public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24" #32 IPs
  map_public_ip_on_launch = true           # public subnet
  availability_zone       = "us-east-1b"
}

# Creating 1st private subnet 
resource "aws_subnet" "felipe_private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.101.0/24" #32 IPs
  map_public_ip_on_launch = false         # private subnet
  availability_zone       = "us-east-1a"
}

# Creating 2nd private subnet
resource "aws_subnet" "felipe_private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.102.0/24" #32 IPs
  map_public_ip_on_launch = false          # private subnet
  availability_zone       = "us-east-1b"
}

#####
# Route Tables #
#####

# route table for public subnet - connecting to Internet gateway
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# route table - connecting to NAT
resource "aws_route_table" "rt_nat_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_for_private_subnet.id
  }
}

# associate the route table with public subnet 1
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.felipe_public_subnet_1.id
  route_table_id = aws_route_table.rt_public.id
}

# associate the route table with public subnet 2
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.felipe_public_subnet_2.id
  route_table_id = aws_route_table.rt_public.id
}

# associate the route table with private subnet 1
resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.felipe_private_subnet_1.id
  route_table_id = aws_route_table.rt_nat_private.id
}

# associate the route table with private subnet 2
resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.felipe_private_subnet_2.id
  route_table_id = aws_route_table.rt_nat_private.id
}


#####
# Security Groups #
#####

##RDS
resource "aws_security_group" "rds_sg" {
  name        = "felipe-sg-rds"
  description = "My Security Group Description"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir tráfego SSH de qualquer lugar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir todo o tráfego de saída
  }

  tags = {
    Name = "felipe_sg_rds"
  }
}

##load balancer
resource "aws_security_group" "lb_sg" {
  name   = "security_group_for_lb"
  vpc_id = aws_vpc.vpc.id
  
  ingress {
    description      = "Allow http request from anywhere"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "Allow https request from anywhere"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "felipe_lb_sg"
  }
}

##EC2
resource "aws_security_group" "web_sg" {
    name = "felipe_web_sg"
    description = "Security group for web servers"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "Allow HTTP inbound traffic"
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow SSH inbound traffic"
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "felipe_web_sg"
    }
}

#####
# DB subnet group #
#####

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "felipe_db_subnet_group"
    description = "DB subnet group"
    subnet_ids = [aws_subnet.felipe_private_subnet_1.id, aws_subnet.felipe_private_subnet_2.id]
    tags = {
        Name = "felipe_db_subnet_group"
    }
}

#####
# MySQL RDS DB#
#####

resource "aws_db_instance" "database" {
  db_name              = "dbfelipe"
  allocated_storage    = var.settings.database.allocated_storage
  storage_type         = var.settings.database.storage_type
  engine               = var.settings.database.engine
  engine_version       = var.settings.database.engine_version
  instance_class       = var.settings.database.instance_class
  username             = "root"
  password             = "root12345"
  parameter_group_name = var.settings.database.parameter_group_name
  skip_final_snapshot  = var.settings.database.skip_final_snapshot
  publicly_accessible  = var.settings.database.publicly_accessible
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period = var.settings.database.backup_retention_period
  backup_window = var.settings.database.backup_window
  maintenance_window = var.settings.database.maintenance_window
  multi_az = var.settings.database.multi_az
}

#####
#Elastic IP#
#####

resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.igw]
  vpc        = true
  tags = {
    Name = "EIP_for_NAT"
  }
}

#####
# NAT Gateway private subnets #
#####

resource "aws_nat_gateway" "nat_for_private_subnet" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.felipe_public_subnet_1.id # nat should be in public subnet

  tags = {
    Name = "Sh NAT for private subnet"
  }

  depends_on = [aws_internet_gateway.igw]
}

#####
# Load Balancer #
#####

resource "aws_lb" "lb" {
    name               = "felipelb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb_sg.id]
    subnets            = [aws_subnet.felipe_public_subnet_1.id, aws_subnet.felipe_public_subnet_2.id]
    depends_on         = [aws_internet_gateway.igw]

    tags = {
        Name = "felipe_lb" 
    }
}

resource "aws_lb_target_group" "tg" {
    name = "targetgroup"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc.id

    health_check {
        interval            = 20
        path                = "/healthcheck"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
        matcher = "200"
    }

    tags = {
        Name = "felipe_tg"
    }
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.lb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}

#####
# Auto Scaling Group #
#####

resource "aws_launch_template" "web_template" {
    name = "felipe_web_template1"
    image_id = "ami-0fc5d935ebf8bc3bc"
    instance_type = var.settings.web_app.instance_type
    user_data = base64encode(<<-EOF
      #!/bin/bash
      export DEBIAN_FRONTEND=noninteractive
      
      sudo apt-get update
      sudo apt-get install -y python3-pip python3-venv git

      # Criação do ambiente virtual e ativação
      python3 -m venv /home/ubuntu/myappenv
      source /home/ubuntu/myappenv/bin/activate

      # Clonagem do repositório da aplicação
      git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp

      # Instalação das dependências da aplicação
      pip install -r /home/ubuntu/myapp/requirements.txt

      sudo apt-get install -y uvicorn
  
      # Configuração da variável de ambiente para o banco de dados
      export DATABASE_URL="mysql+pymysql://root:root12345@${aws_db_instance.database.endpoint}/dbfelipe"

      cd /home/ubuntu/myapp
      # Inicialização da aplicação
      uvicorn main:app --host 0.0.0.0 --port 80 
      EOF 
    )

    network_interfaces {
        security_groups = [ aws_security_group.web_sg.id ]
        associate_public_ip_address = true
        subnet_id = aws_subnet.felipe_public_subnet_1.id
    }
    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "felipe_ec2_template"
        }
    }
}

resource "aws_autoscaling_group" "web_asg" {
    name = "web_asg"
    desired_capacity = 3
    max_size = 6
    min_size = 2
    
    vpc_zone_identifier = [aws_subnet.felipe_public_subnet_1.id]
    target_group_arns = [aws_lb_target_group.tg.arn]

    launch_template {
        id = aws_launch_template.web_template.id
        version = "$Latest"
    }

    health_check_grace_period = 300
    health_check_type = "ELB"
    force_delete = true

    tag {
        key = "Name"
        value = "felipe_web_asg"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_policy" "felipe_subir_escala" {
  name = "felipe_subir_escala"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_autoscaling_policy" "felipe_descer_escala" {
  name = "felipe_descer_escala"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "felipe_alarme_subir" {
  alarm_name = "felipe_alarme_subir"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "70"
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = [aws_autoscaling_policy.felipe_subir_escala.arn]
  ok_actions = [aws_autoscaling_policy.felipe_descer_escala.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "felipe_alarme_descer" {
  alarm_name = "felipe_alarme_descer"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "10"
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = [aws_autoscaling_policy.felipe_descer_escala.arn]
  ok_actions = [aws_autoscaling_policy.felipe_subir_escala.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}