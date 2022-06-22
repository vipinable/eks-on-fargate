resource "aws_iam_role" "eks_admin_role" {
  name = "eks_admin_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "arn:aws:iam::731685434595:user/apiuser"
          ]
        }
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      },
    ]
  })
}


resource "aws_iam_policy" "eks_admin_policy" {
  name   = "eks_admin_policy"
  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
})
}



resource "aws_iam_policy_attachment" "eks_policy_attachment" {
name       = "eks_policy_attachment"
roles      = [aws_iam_role.eks_admin_role.id]
policy_arn = aws_iam_policy.eks_admin_policy.arn
}


resource "aws_iam_policy" "kube_admin_sts_policy" {
  name   = "eks_sts_policy"
  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "${aws_iam_role.eks_admin_role.arn}"
        }
    ]
})
}


resource "aws_iam_user" "kube_admin" {
  name = "kube_admin"
}


resource "aws_iam_policy_attachment" "user_policy_attach" {
  depends_on = [aws_iam_user.kube_admin]
  name = "user_policy_attach"
  users = [aws_iam_user.kube_admin.name]
  policy_arn = aws_iam_policy.kube_admin_sts_policy.arn
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster_name
}

provider "kubernetes" {
  host = aws_eks_cluster.cluster01.endpoint
  token = data.aws_eks_cluster_auth.cluster_auth.token
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.cluster01.certificate_authority.0.data)}"
}

resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(
            concat(
                    [
                      {
                        rolearn : "${aws_iam_role.eks-node_role.arn}"
                        username : "system:node : { { EC2PrivateDNSName } }"
                        groups = ["system:bootstrappers", "system:nodes"]
                      },
                      {
                        rolearn: "${aws_iam_role.eks_admin_role.arn}"
                        username: "kube_admin"
                        groups = [
                          "system:masters"
                        ]
                      }
                    ]
            )
    )
  }
}

locals {
  kubeconfig = <<EOF
apiVersion : v1
clusters :
- cluster:
    server : "${aws_eks_cluster.cluster01.endpoint}"
    certificate-authority-data : "${aws_eks_cluster.cluster01.certificate_authority.0.data}"
  name : "${aws_eks_cluster.cluster01.arn}"
contexts :
- context:
    cluster : "${aws_eks_cluster.cluster01.arn}"
    user : "${aws_eks_cluster.cluster01.arn}"
  name : "${aws_eks_cluster.cluster01.arn}"
current-context : "${aws_eks_cluster.cluster01.arn}"
kind : Config
preferences : {}
users :
- name: "${aws_eks_cluster.cluster01.arn}"
  user :
    exec:
      apiVersion : client.authentication.k8s.io/v1beta1
      args :
        - --region
        - us-west-2
        - eks
        - get-token
        - --cluster-name
        - cluster_01
      command : aws
  EOF
}


output "kubeconfig" {
  value = "${local.kubeconfig}"
}
