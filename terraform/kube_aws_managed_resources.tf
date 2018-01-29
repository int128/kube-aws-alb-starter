# References to resources managed by kops.

# VPC for the Kubernetes cluster
data "aws_vpc" "k8s_vpc" {
  tags = "${map("kubernetes.io/cluster/${var.k8s_cluster_name}", "owned")}"
}

# Subnets for the Kubernetes cluster
data "aws_subnet_ids" "k8s_subnets" {
  vpc_id = "${data.aws_vpc.k8s_vpc.id}"
}

# Auto Scaling Group for the Kubernetes nodes
data "aws_autoscaling_groups" "k8s_nodes" {
  filter {
    name = "key"
    values = ["aws:cloudformation:logical-id"]
  }
  filter {
    name = "value"
    values = ["Workers"]
  }
  # TODO: filter by the cluster name
}

# Security Group for the Kubernetes nodes
data "aws_security_group" "k8s_nodes" {
  tags {
    Name = "${var.k8s_cluster_name}-sg-worker"
  }
}
