# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.pub_sub_1a_id,var.pub_sub_2b_id]
  enable_deletion_protection = false

  tags   = {
    Name = "${var.project_name}-alb"
  }
}

# create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project_name}-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create a listener on port 80 with redirect action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.alb_target_group]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

}

data "aws_route53_zone" "public-zone" {
  name = var.hosted_zone_name
  private_zone = false
}


resource "aws_acm_certificate" "alb_certificate" {
  domain_name               = "${var.sub_domain}.${var.hosted_zone_name}"
  validation_method         = "DNS"
tags = {
    Environment = "dev"
  }
lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_certificate_validation" {
  
   for_each = {
    for dvo in aws_acm_certificate.alb_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public-zone.zone_id
}


resource "aws_acm_certificate_validation" "alb_certificate_validation" {
  certificate_arn         = aws_acm_certificate.alb_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_certificate_validation : record.fqdn]
}

resource "aws_lb_listener_certificate" "alb_listener_certificate" {
  listener_arn    = aws_lb_listener.https_listener.arn
  certificate_arn = aws_acm_certificate.alb_certificate.arn
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn =  aws_lb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate.alb_certificate.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  depends_on        = [aws_acm_certificate_validation.alb_certificate_validation]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

}
