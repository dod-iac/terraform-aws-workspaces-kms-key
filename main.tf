/**
 * ## Usage
 *
 * Creates a KMS Key for use with Amazon Workspaces.
 *
 * ```hcl
 * module "workspaces_kms_key" {
 *   source = "dod-iac/workspaces-kms-key/aws"
 *
 *   name = format("alias/app-%s-workspaces-%s", var.application, var.environment)
 *   description = format("A KMS key used to encrypt data at rest in Amazon Workspaces for %s:%s.", var.application, var.environment)
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 * ## Terraform Version
 *
 * Terraform 0.12. Pin module version to "~> 1.0.0". Submit pull-requests to "master" branch.
 *
 * Terraform 0.11 is not supported.
 *
 * ## Contributing
 *
 * We'd love to have your contributions! Please see CONTRIBUTING.md for more info.
 *
 * ## Security
 *
 * Please see SECURITY.md for more info.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# https://docs.aws.amazon.com/kms/latest/developerguide/services-workspaces.html

data "aws_iam_policy_document" "workspaces" {
  policy_id = "key-policy-workspaces"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.partition,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow access through Workspaces for all principals in the account that are authorized to use Workspaces"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["workspaces.us-gov-west-1.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
    }
  }
}

resource "aws_kms_key" "workspaces" {
  description             = var.description
  deletion_window_in_days = var.key_deletion_window_in_days
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.workspaces.json
  tags                    = var.tags
}

resource "aws_kms_alias" "workspaces" {
  name          = var.name
  target_key_id = aws_kms_key.workspaces.key_id
}
