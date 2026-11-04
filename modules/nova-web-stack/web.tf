data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix            = "${local.name_prefix}-web-"
  image_id               = data.aws_ami.debian.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.sg_web.security_group_id]

  iam_instance_profile {
    name = local.instance_profile_name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(templatefile("${path.module}/bootstrap.sh.tftpl", {
    aws_region            = var.aws_region
    environment           = var.environment
    secret_parameter_name = aws_ssm_parameter.app_secret.name
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${local.name_prefix}-web"
      Project     = "NovaSphere"
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }

  update_default_version = true
  depends_on             = [aws_iam_role_policy.read_app_secret]
}

resource "aws_lb" "web" {
  name                       = "ns-${var.environment}-${var.owner}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [module.sg_alb.security_group_id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name        = "${local.name_prefix}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "web" {
  name        = "ns-${var.environment}-${var.owner}-web"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = {
    Name        = "${local.name_prefix}-web"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-web"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  health_check_grace_period = 300
  force_delete              = false

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "NovaSphere"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = var.owner
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}
