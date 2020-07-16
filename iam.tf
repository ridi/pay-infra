data "aws_iam_policy_document" "ridi_pay_frontend" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ridi_pay_frontend.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.ridi_pay_frontend.iam_arn]
    }
  }

  # CloudFront cannot determine whether a requested resource exists in
  # S3 bucket unless it has ListBucket permission.
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.ridi_pay_frontend.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.ridi_pay_frontend.iam_arn]
    }
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-${module.global_variables.env}"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name               = "bastion-${module.global_variables.env}"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# users
resource "aws_iam_user" "hoseongson" {
  name = "hoseong.son"
}

resource "aws_iam_user" "jaeyongkwack" {
  name = "jaeyongkwack"
}

# developers group
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/users/"
}

resource "aws_iam_group_membership" "developers" {
  name = "developers"

  users = [
    aws_iam_user.hoseongson.name,
    aws_iam_user.jaeyongkwack.name
  ]

  group = aws_iam_group.developers.name
}

resource "aws_iam_group_policy_attachment" "developers_read_only_policy_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_policy" "developers_extra_policy" {
  name  = "developers-extra-policy"
  group = aws_iam_group.developers.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:*"
      ],
      "Effect": "Deny",
      "Resource": "*"
    },
    {
      "Sid": "AllowViewAccountInfo",
      "Effect": "Allow",
      "Action": [
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary",
          "iam:ListVirtualMFADevices"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowManageOwnPasswords",
      "Effect": "Allow",
      "Action": [
          "iam:ChangePassword",
          "iam:GetUser"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    },
    {
      "Sid": "ManageOwnAccessKeys",
      "Effect": "Allow",
      "Action": [
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:GetAccessKeyLastUsed",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    },
    {
      "Sid": "AllowManageOwnVirtualMFADevice",
      "Effect": "Allow",
      "Action": [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
      ],
      "Resource": "arn:aws:iam::*:mfa/$${aws:username}"
    },
    {
      "Sid": "AllowManageOwnUserMFA",
      "Effect": "Allow",
      "Action": [
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    },
    {
      "Action": [
        "logs:PutQueryDefinition"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
    ]
}
EOF
}
