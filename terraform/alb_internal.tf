# Internal ALB for services.
# This is needed if the security group of the external ALB is not open,
# because k8s nodes can not access to services via the external ALB.

resource "aws_lb" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  name = "alb-int-${local.alb_name_hash}"
  load_balancer_type = "application"
  internal = true
  idle_timeout = 180
  subnets = ["${data.aws_subnet_ids.k8s_subnets.ids}"]
  security_groups = ["${aws_security_group.alb_internal.id}"]
  tags {
    KubernetesCluster = "${var.k8s_cluster_name}"
  }
}

resource "aws_security_group" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  description = "Security group for internal ALB"
  vpc_id = "${data.aws_vpc.k8s_vpc.id}"
  ingress {
    description = "Allow from Kubernetes nodes"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${data.aws_security_group.k8s_nodes.id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "alb.int.nodes.${var.k8s_cluster_name}"
    KubernetesCluster = "${var.k8s_cluster_name}"
  }
}

resource "aws_security_group_rule" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  description = "Allow from internal ALB"
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  source_security_group_id = "${aws_security_group.alb_internal.id}"
  security_group_id = "${data.aws_security_group.k8s_nodes.id}"
}

resource "aws_lb_listener" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  load_balancer_arn = "${aws_lb.alb_internal.arn}"
  port = 443
  protocol = "HTTPS"
  certificate_arn = "${data.aws_acm_certificate.service.arn}"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  default_action {
    target_group_arn = "${aws_lb_target_group.alb_internal.arn}"
    type = "forward"
  }
}

resource "aws_lb_target_group" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  name = "alb-int-${local.alb_name_hash}"
  port = 30080
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.k8s_vpc.id}"
  health_check {
    path = "/healthz"
  }
  tags {
    KubernetesCluster = "${var.k8s_cluster_name}"
  }
}

resource "aws_autoscaling_attachment" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  autoscaling_group_name = "${join(",", data.aws_autoscaling_groups.k8s_nodes.names)}"
  alb_target_group_arn = "${aws_lb_target_group.alb_internal.arn}"
}
