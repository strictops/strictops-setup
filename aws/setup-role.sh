#!/bin/bash
#
# StrictOps IAM Role Setup Script
# Usage: curl -sSL https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/setup-role.sh | bash -s -- --external-id <ID> --strictops-account <ACCOUNT>
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
STACK_NAME="strictops-cross-account-role-${ROLE_NAME}"
ROLE_NAME="StrictOpsAccess"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
TEMPLATE_URL="https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/cross-account-role.yaml"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --external-id)
      EXTERNAL_ID="$2"
      shift 2
      ;;
    --strictops-account)
      STRICTOPS_ACCOUNT_ID="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --role-name)
      ROLE_NAME="$2"
      shift 2
      ;;
    --help)
      echo "Usage: setup-role.sh --external-id <ID> --strictops-account <ACCOUNT> [--region <REGION>] [--role-name <NAME>]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$EXTERNAL_ID" ]]; then
  echo -e "${RED}Error: --external-id is required${NC}"
  exit 1
fi

if [[ -z "$STRICTOPS_ACCOUNT_ID" ]]; then
  echo -e "${RED}Error: --strictops-account is required${NC}"
  exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  StrictOps IAM Role Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Region:            ${YELLOW}$REGION${NC}"
echo -e "  Role Name:         ${YELLOW}$ROLE_NAME${NC}"
echo -e "  External ID:       ${YELLOW}$EXTERNAL_ID${NC}"
echo -e "  StrictOps Account: ${YELLOW}$STRICTOPS_ACCOUNT_ID${NC}"
echo ""

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
  echo -e "${RED}Error: AWS CLI is not installed${NC}"
  echo "Install it from: https://aws.amazon.com/cli/"
  exit 1
fi

# Check AWS credentials
echo -e "${BLUE}[1/3]${NC} Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}Error: AWS credentials not configured${NC}"
  echo "Run 'aws configure' or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
  exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "      Logged in to AWS account: ${GREEN}$ACCOUNT_ID${NC}"

# Download and deploy CloudFormation template
echo -e "${BLUE}[2/3]${NC} Deploying CloudFormation stack..."
echo "      Downloading template from GitHub..."

TEMP_FILE=$(mktemp)
curl -sSL "$TEMPLATE_URL" -o "$TEMP_FILE"

echo "      Creating/updating stack '$STACK_NAME'..."
aws cloudformation deploy \
  --capabilities CAPABILITY_NAMED_IAM \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMP_FILE" \
  --parameter-overrides \
    RoleName="$ROLE_NAME" \
    ExternalId="$EXTERNAL_ID" \
    StrictOpsAccountId="$STRICTOPS_ACCOUNT_ID" \
  --region "$REGION" \
  --no-fail-on-empty-changeset

rm -f "$TEMP_FILE"
echo -e "      Stack deployed ${GREEN}successfully${NC}"

# Get the Role ARN
echo -e "${BLUE}[3/3]${NC} Retrieving Role ARN..."
ROLE_ARN=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='StrictOpsRoleArn'].OutputValue | [0]" \
  --output text \
  --region "$REGION")

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Copy this Role ARN and paste it in StrictOps:"
echo ""
echo -e "  ${YELLOW}$ROLE_ARN${NC}"
echo ""
