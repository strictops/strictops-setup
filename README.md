# StrictOps Setup

Setup scripts for connecting your cloud accounts to StrictOps.

## AWS Setup

The setup script creates an IAM role that allows StrictOps to deploy and manage resources in your AWS account.

### Quick Start

Run one of these commands in your terminal (requires [AWS CLI](https://aws.amazon.com/cli/)):

#### Mac / Linux

```bash
curl -sSL https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/setup-role.sh | bash -s -- \
  --external-id <YOUR_EXTERNAL_ID> \
  --strictops-account <STRICTOPS_ACCOUNT_ID>
```

#### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/setup-role.ps1 | iex; `
Setup-StrictOpsRole `
  -ExternalId "<YOUR_EXTERNAL_ID>" `
  -StrictOpsAccountId "<STRICTOPS_ACCOUNT_ID>"
```

Replace `<YOUR_EXTERNAL_ID>` and `<STRICTOPS_ACCOUNT_ID>` with the values provided in the StrictOps console during onboarding.

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--external-id` | Yes | External ID provided by StrictOps |
| `--strictops-account` | Yes | StrictOps AWS account ID |
| `--region` | No | AWS region (default: `us-east-1` or `AWS_DEFAULT_REGION`) |
| `--role-name` | No | IAM role name (default: `StrictOpsAccess`) |

### What It Does

1. Validates your AWS credentials
2. Deploys a CloudFormation stack that creates an IAM role
3. Outputs the Role ARN to paste into StrictOps

### Permissions

The IAM role grants StrictOps permissions to:

- **ECS** - Create and manage clusters, services, and task definitions
- **ECR** - Create repositories and push container images
- **ELB** - Create and configure load balancers and target groups
- **EC2** - Create security groups and describe VPCs/subnets
- **CloudWatch Logs** - Create log groups and read logs
- **CloudFormation** - Deploy and manage stacks
- **IAM** - Create roles for ECS task execution

### Manual Setup

If you prefer to set up the IAM role manually, use the CloudFormation template directly:

```bash
aws cloudformation deploy \
  --capabilities CAPABILITY_NAMED_IAM \
  --stack-name strictops-cross-account-role \
  --template-file aws/cross-account-role.yaml \
  --parameter-overrides \
    ExternalId=<YOUR_EXTERNAL_ID> \
    StrictOpsAccountId=<STRICTOPS_ACCOUNT_ID>
```

## Support

For help, contact [support@strictops.io](mailto:support@strictops.io).
