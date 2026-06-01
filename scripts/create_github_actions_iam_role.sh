#!/bin/bash

#   Usage
#   ./create_github_actions_iam_role.sh <GITHUB_ORG> <GITHUB_REPO> <ROLE_NAME> [BRANCH]
#
#   Example:
#   ./create_github_actions_iam_role.sh myorg myrepo Github-actions-backend "*"
#
#   Creates the IAM role required for the CI/CD pipeline, granting access to:
#     - ECR  : authenticate, push, and pull images
#     - ECS  : register task definitions, describe/update services and clusters
#     - IAM  : pass ECS task execution and task roles
#
#   The role uses GitHub OIDC as the trust provider so no long-lived credentials
#   are stored in GitHub Secrets.
#
#   Note: All resource ARNs are set to wildcard (*) so the same role can be
#   reused across multiple services and clusters. Tighten the ARNs for
#   production environments to follow least-privilege principles.

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────
GITHUB_ORG="${1:?Usage: $0 <GITHUB_ORG> <GITHUB_REPO> <ROLE_NAME> [BRANCH]}"
GITHUB_REPO="${2:?Usage: $0 <GITHUB_ORG> <GITHUB_REPO> <ROLE_NAME> [BRANCH]}"
ROLE_NAME="${3:?Usage: $0 <GITHUB_ORG> <GITHUB_REPO> <ROLE_NAME> [BRANCH]}"
BRANCH="${4:-*}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="${AWS_REGION:-us-east-1}"
OIDC_PROVIDER="token.actions.githubusercontent.com"

echo "Creating IAM role '${ROLE_NAME}' for repo ${GITHUB_ORG}/${GITHUB_REPO} (branch: ${BRANCH})"
echo "AWS Account : ${AWS_ACCOUNT_ID}"
echo "AWS Region  : ${AWS_REGION}"

# ── Trust policy (GitHub OIDC) ────────────────────────────────────────────────
TRUST_POLICY=$(cat <<TRUSTEOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${OIDC_PROVIDER}:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "${OIDC_PROVIDER}:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/${BRANCH}"
                }
            }
        }
    ]
}
TRUSTEOF
)

# ── Permissions policy ────────────────────────────────────────────────────────
PERMISSIONS_POLICY='{
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
            "Resource": "*"
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
            "Resource": "*"
        },
        {
            "Sid": "PassRoleToECS",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "ecs-tasks.amazonaws.com"
                }
            }
        }
    ]
}'

POLICY_NAME="${ROLE_NAME}-policy"

# ── Create or update the IAM role ─────────────────────────────────────────────
if aws iam get-role --role-name "${ROLE_NAME}" &>/dev/null; then
    echo "Role '${ROLE_NAME}' already exists — updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-document "${TRUST_POLICY}"
else
    echo "Creating role '${ROLE_NAME}'..."
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document "${TRUST_POLICY}" \
        --description "GitHub Actions OIDC role for ${GITHUB_ORG}/${GITHUB_REPO}"
fi

# ── Attach inline permissions policy ─────────────────────────────────────────
echo "Putting inline policy '${POLICY_NAME}'..."
aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${POLICY_NAME}" \
    --policy-document "${PERMISSIONS_POLICY}"

ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query "Role.Arn" --output text)
echo ""
echo "Done. Role ARN: ${ROLE_ARN}"
echo "Add this to your workflow env:"
echo "  GITHUB_ACTION_IAM_ROLE: ${ROLE_ARN}"
