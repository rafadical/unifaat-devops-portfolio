data "aws_iam_policy_document" "s3_read" {
  statement {
    sid    = "ListAndReadTechNovaBuckets"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "arn:aws:s3:::technova-*",
      "arn:aws:s3:::technova-*/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read" {
  name        = "SEURA-technova-s3-read"
  path        = "/technova/"
  description = "Permite leitura de buckets TechNova com menor privilégio"
  policy      = data.aws_iam_policy_document.s3_read.json
  tags        = local.common_tags
}

data "aws_iam_policy_document" "ec2_s3_full" {
  statement {
    sid    = "AllowEC2ControlOnTechNova"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid    = "ReadWriteTechNovaAppData"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "arn:aws:s3:::technova-app-data-*",
      "arn:aws:s3:::technova-app-data-*/*",
    ]
  }
}

resource "aws_iam_policy" "ec2_s3_full" {
  name        = "SEURA-technova-ec2-s3-full"
  path        = "/technova/"
  description = "Permite acesso de plataforma para EC2 + S3 em buckets da TechNova"
  policy      = data.aws_iam_policy_document.ec2_s3_full.json
  tags        = local.common_tags
}

data "aws_iam_policy_document" "deny_destructive" {
  statement {
    sid    = "DenyDestructiveOperations"
    effect = "Deny"

    actions = [
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "ec2:TerminateInstances",
      "ec2:DeleteVolume",
      "ec2:DeleteSnapshot",
      "iam:DeleteUser",
      "iam:DeleteGroup",
      "iam:DeleteRole",
      "iam:DeletePolicy",
      "iam:DeleteAccessKey",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "deny_destructive" {
  name        = "SEURA-technova-deny-destructive"
  path        = "/technova/"
  description = "Proteção extra para bloquear ações destrutivas em ambientes de desenvolvimento"
  policy      = data.aws_iam_policy_document.deny_destructive.json
  tags        = local.common_tags
}

resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}

resource "aws_iam_group_policy_attachment" "platform_eng_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}
