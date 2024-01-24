
data "aws_route53_zone" "public-zone" {
  name         = var.hosted_zone_name
  private_zone = false

}

resource "aws_route53_record" "application_load_balancer_record" {
  name    = "${var.sub_domain}.${data.aws_route53_zone.public-zone.name}"
  zone_id = data.aws_route53_zone.public-zone.zone_id
  type    = "A"

  alias {
   name    = var.alb_dns_name
   zone_id =  var.alb_zone_id
   evaluate_target_health = false
  }
}
