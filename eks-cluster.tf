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
      name = var.node_group1

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = var.node_group2

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

locals {
  node1_arn = module.eks.eks_managed_node_groups.one.iam_role_name
  node2_arn = module.eks.eks_managed_node_groups.two.iam_role_name

}

output "eks_node1_arn" {
  value = local.node1_arn
}

output "eks_node2_arn" {
  value = local.node1_arn
}

resource "aws_iam_role_policy_attachment" "custom_nodegroup_policy_node1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role       =  local.node1_arn
}

resource "aws_iam_role_policy_attachment" "custom_nodegroup_policy_node2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role       =  local.node2_arn
}

data "aws_iam_policy_document" "sqs_publish_policy" {
  source_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"],
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

resource "aws_iam_role_policy_attachment" "sqs_publish_policy_attachment_node1" {
  policy_arn = aws_iam_policy.sqs_publish_policy.arn
  role       = local.node1_arn
}

resource "aws_iam_role_policy_attachment" "sqs_publish_policy_attachment_node2" {
  policy_arn = aws_iam_policy.sqs_publish_policy.arn
  role       = local.node2_arn
}

data "aws_iam_policy_document" "s3_put_policy" {
  source_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*Object",
      "Resource": "${aws_s3_bucket.final-bucket.arn}/*"
    }
  ]
}
JSON
}

resource "aws_iam_policy" "s3_put_policy" {
  name        = "s3-put-policy"
  description = "IAM policy for adding file in the s3 bucket"
  policy      = data.aws_iam_policy_document.s3_put_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attachment_node1" {
  policy_arn = aws_iam_policy.s3_put_policy.arn
  role       = local.node1_arn
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attachment_node2" {
  policy_arn = aws_iam_policy.s3_put_policy.arn
  role       = local.node2_arn
}
