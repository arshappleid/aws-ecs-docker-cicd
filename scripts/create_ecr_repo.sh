#!/bin/bash
set -euo pipefail

# Usage: ./create_ecr_repo.sh <frontend-repo-name> <backend-repo-name>
#
# Example:
#   ./create_ecr_repo.sh my-app-frontend my-app-backend

FRONTEND_REPO="${1:-}"
BACKEND_REPO="${2:-}"


if [[ -z "$FRONTEND_REPO" || -z "$BACKEND_REPO" ]]; then
  echo "Error: Both repository names are required."
  echo "Usage: $0 <frontend-repo-name> <backend-repo-name>"
  exit 1
fi


create_repo() {
  local NAME="$1"
  local LABEL="$2"

  echo "Creating ECR repository for $LABEL: $NAME ..."

  aws ecr create-repository \
    --repository-name "$NAME" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE \
    --query "repository.repositoryUri" \
    --output text

  echo "$LABEL repository created successfully."
  echo "---"
}

# ── Create repos ──────────────────────────────────────────────────────────────
create_repo "$FRONTEND_REPO" "Frontend"
create_repo "$BACKEND_REPO"  "Backend"

echo "ECR repositories have been created."
