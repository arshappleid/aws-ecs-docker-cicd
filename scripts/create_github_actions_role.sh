#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# create_github_actions_role.sh
# Creates an IAM OIDC provider for GitHub Actions and an IAM role that
# GitHub Actions workflows can assume via OIDC (no long-lived credentials).
#
# Usage:
#   ./scripts/create_github_actions_role.sh <github-org>/<github-repo> [BRANCH] [AWS_REGION]
#
# Arguments:
#   $1  github-org/github-repo  (required)
#   $2  branch name or '*' for all branches  (optional, default: *)
#   $3  AWS region               (optional, default: us-east-1)
#
# Example:
#   ./scripts/create_github_actions_role.sh myorg/aws-ecs-docker-cicd main us-east-1
#   ./scripts/create_github_actions_role.sh myorg/aws-ecs-docker-cicd
# ---------------------------------------------------------------------------

GITHUB_REPO="${1:-}"
BRANCH="${2:-*}"
AWS_REGION="${3:-us-east-1}"

if [[ -z "${GITHUB_REPO}" ]]; then
  echo "Error: GitHub repository is required."
  echo "Usage: $0 <github-org>/<github-repo> [BRANCH] [AWS_REGION]"
  exit 1
fi

GITHUB_ORG="${GITHUB_REPO%%/*}"
OIDC_URL="https://token.actions.githubusercontent.com"
OIDC_THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
ROLE_NAME="GitHubActionsRole"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: ${AWS_ACCOUNT_ID} | Region: ${AWS_REGION}"
echo "GitHub repo: ${GITHUB_REPO} | Branch: ${BRANCH}"

# ── OIDC Provider ──────────────────────────────────────────────────────────
EXISTING_PROVIDER=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text 2>/dev/null || echo "")

if [[ -n "${EXISTING_PROVIDER}" ]]; then
  echo "OIDC provider already exists: ${EXISTING_PROVIDER}"
  PROVIDER_ARN="${EXISTING_PROVIDER}"
else
  echo "Creating OIDC provider for GitHub Actions..."
  PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
    --url "${OIDC_URL}" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "${OIDC_THUMBPRINT}" \
    --query "OpenIDConnectProviderArn" \
    --output text)
  echo "OIDC provider created: ${PROVIDER_ARN}"
fi

# ── Trust policy ───────────────────────────────────────────────────────────
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:ref:refs/heads/${BRANCH}"
        }
      }
    }
  ]
}
EOF
)

# ── IAM Role ───────────────────────────────────────────────────────────────
EXISTING_ROLE=$(aws iam get-role --role-name "${ROLE_NAME}" \
  --query "Role.Arn" --output text 2>/dev/null || echo "")

if [[ -n "${EXISTING_ROLE}" ]]; then
  echo "Role already exists: ${EXISTING_ROLE}"
  echo "Updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document "${TRUST_POLICY}"
  ROLE_ARN="${EXISTING_ROLE}"
else
  echo "Creating IAM role: ${ROLE_NAME}..."
  ROLE_ARN=$(aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "${TRUST_POLICY}" \
    --description "Assumed by GitHub Actions via OIDC for ${GITHUB_REPO}" \
    --query "Role.Arn" \
    --output text)
  echo "Role created: ${ROLE_ARN}"
fi

# ── Inline policy: ECR + ECS permissions (broadly over-provisioned) ────────
CICD_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:*:${AWS_ACCOUNT_ID}:repository/*"
    },
    {
      "Sid": "ECSTaskDefinitionGlobal",
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSClusterOperations",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ],
      "Resource": [
        "arn:aws:ecs:*:${AWS_ACCOUNT_ID}:cluster/*",
        "arn:aws:ecs:*:${AWS_ACCOUNT_ID}:service/*"
      ]
    },
    {
      "Sid": "PassRoleToECS",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/*",
      "Condition": {
        "StringLike": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    }
  ]
}
EOF
)

echo "Putting inline policy: GitHubActionsCICD..."
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "GitHubActionsCICD" \
  --policy-document "${CICD_POLICY}"

echo ""
echo "Done. Add the following secret to your GitHub repository:"
echo "  AWS_ROLE_ARN = ${ROLE_ARN}"
