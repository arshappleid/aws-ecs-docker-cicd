
set -euo pipefail












POOL_NAME="${1:-my-project-users}"
APP_CLIENT_NAME="${2:-my-project-client}"
AWS_REGION="${3:-us-east-1}"

echo "Creating Cognito User Pool: ${POOL_NAME} in ${AWS_REGION}..."


POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name "${POOL_NAME}" \
  --region "${AWS_REGION}" \
  --policies '{
    "PasswordPolicy": {
      "MinimumLength": 8,
      "RequireUppercase": true,
      "RequireLowercase": true,
      "RequireNumbers": true,
      "RequireSymbols": false,
      "TemporaryPasswordValidityDays": 7
    }
  }' \
  --auto-verified-attributes email \
  --username-attributes email \
  --mfa-configuration OFF \
  --account-recovery-setting '{
    "RecoveryMechanisms": [
      { "Priority": 1, "Name": "verified_email" }
    ]
  }' \
  --schema '[
    {
      "Name": "email",
      "AttributeDataType": "String",
      "Required": true,
      "Mutable": true
    }
  ]' \
  --query "UserPool.Id" \
  --output text)

echo "User Pool created: ${POOL_ID}"


echo "Creating App Client: ${APP_CLIENT_NAME}..."

CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id "${POOL_ID}" \
  --client-name "${APP_CLIENT_NAME}" \
  --region "${AWS_REGION}" \
  --no-generate-secret \
  --explicit-auth-flows \
    "ALLOW_USER_SRP_AUTH" \
    "ALLOW_REFRESH_TOKEN_AUTH" \
    "ALLOW_USER_PASSWORD_AUTH" \
  --token-validity-units '{
    "AccessToken": "hours",
    "IdToken": "hours",
    "RefreshToken": "days"
  }' \
  --access-token-validity 1 \
  --id-token-validity 1 \
  --refresh-token-validity 30 \
  --prevent-user-existence-errors ENABLED \
  --query "UserPoolClient.ClientId" \
  --output text)

echo "App Client created: ${CLIENT_ID}"


echo ""
echo "=============================="
echo "Cognito User Pool Summary"
echo "=============================="
echo "  Pool Name   : ${POOL_NAME}"
echo "  Pool ID     : ${POOL_ID}"
echo "  App Client  : ${APP_CLIENT_NAME}"
echo "  Client ID   : ${CLIENT_ID}"
echo "  Region      : ${AWS_REGION}"
echo ""
echo "Add these to your application config / environment:"
echo "  COGNITO_USER_POOL_ID = ${POOL_ID}"
echo "  COGNITO_CLIENT_ID    = ${CLIENT_ID}"
echo "  AWS_REGION           = ${AWS_REGION}"
