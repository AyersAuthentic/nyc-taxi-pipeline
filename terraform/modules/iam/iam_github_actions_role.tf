# -----------------------------------------------------------------------------
# IAM OIDC Provider for GitHub Actions
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions_oidc_provider" {
  url = "https://${var.github_oidc_provider_url}"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = var.tags
}


# -----------------------------------------------------------------------------
# IAM Role for GitHub Actions Deployment (Role-GitHub-Actions-Deploy)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "github_actions_deploy_role" {
  name = "${var.project_name}-Role-GitHub-Actions-Deploy-${var.environment}"


  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions_oidc_provider.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.github_oidc_provider_url}:sub" : "repo:${var.github_org_name}/${var.github_repo_name}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  description = "IAM Role for GitHub Actions to deploy project resources via Terraform."

  tags = merge(var.tags, {
    Name        = "${var.project_name}-Role-GitHub-Actions-Deploy-${var.environment}"
    Description = "IAM Role for GitHub Actions CI/CD deployment"
  })
}





data "aws_iam_policy_document" "github_actions_deploy_permissions_doc" {
  statement {
    sid    = "AllowTerraformToManageProjectResources"
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "rds:*",
      "redshift-serverless:*",
      "redshift-data:*",
      "lambda:*",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfiles",
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:TagResource",
      "cloudwatch:*",
      "logs:*",
      "application-autoscaling:*",
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_deploy_permissions_policy" {
  name        = "${var.project_name}-GitHubActionsDeployPermissions-${var.environment}"
  description = "Broad permissions for GitHub Actions to deploy project resources via Terraform."
  policy      = data.aws_iam_policy_document.github_actions_deploy_permissions_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy_permissions_attach" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = aws_iam_policy.github_actions_deploy_permissions_policy.arn
}
