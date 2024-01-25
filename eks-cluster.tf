module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

data "aws_eks_node_groups" "node_groups" {
  cluster_name = local.cluster_name
}

data "aws_eks_node_group" "node_group_info" {
  for_each = data.aws_eks_node_groups.node_groups.names

  cluster_name    = local.cluster_name
  node_group_name = each.value
}

resource "aws_iam_role_policy_attachment" "custom_nodegroup_policy" {
  for_each   = data.aws_eks_node_groups.node_groups.names
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role       = element(split("/", data.aws_eks_node_group.node_group_info[each.key].node_role_arn), 1)
}

data "aws_iam_policy_document" "sqs_publish_policy" {
  source_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.ms-queue.arn}"
    }
  ]
}
JSON
}

resource "aws_iam_policy" "sqs_publish_policy" {
  name        = "sqs-publish-policy"
  description = "IAM policy for publishing messages to SQS queue"
  policy      = data.aws_iam_policy_document.sqs_publish_policy.json
}

resource "aws_iam_role_policy_attachment" "sqs_publish_policy_attachment" {
  for_each   = data.aws_eks_node_groups.node_groups.names
  policy_arn = aws_iam_policy.sqs_publish_policy.arn
  role       = element(split("/", data.aws_eks_node_group.node_group_info[each.key].node_role_arn), 1)
}
