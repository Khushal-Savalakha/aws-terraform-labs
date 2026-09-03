resource "null_resource" "coredns_patch" {
  provisioner "local-exec" {
    command = <<EOF
aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}
kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]' || true
kubectl rollout restart deployment coredns -n kube-system
EOF
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_fargate_profile.kube_system
  ]
}