data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "SEURA-technova-ec2-role"
  path               = "/technova/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(local.common_tags, {
    Purpose = "Allow EC2 instances to access application data in S3"
  })
}

resource "aws_iam_policy" "ec2_role_s3_app_data" {
  name        = "SEURA-technova-ec2-role-s3-app-data"
  path        = "/technova/"
  description = "Permite que instâncias EC2 façam read/write em buckets technova-app-data-*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAppDataBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "arn:aws:s3:::technova-app-data-*"
      },
      {
        Sid    = "ReadWriteAppDataObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Resource = "arn:aws:s3:::technova-app-data-*/*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Purpose = "Write access to app data buckets"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_s3_app_data" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_role_s3_app_data.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "SEURA-technova-ec2-profile"
  path = "/technova/"
  role = aws_iam_role.ec2_role.name

  tags = merge(local.common_tags, {
    Purpose = "Instance profile for EC2 S3 app data role"
  })
}
