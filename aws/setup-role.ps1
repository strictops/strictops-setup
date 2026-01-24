#
# StrictOps IAM Role Setup Script (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/setup-role.ps1 | iex
#        Then run: Setup-StrictOpsRole -ExternalId <ID> -StrictOpsAccountId <ACCOUNT>
#

function Setup-StrictOpsRole {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExternalId,

        [Parameter(Mandatory=$true)]
        [string]$StrictOpsAccountId,

        [string]$Region = "us-east-1",

        [string]$RoleName = "StrictOpsAccess",

        [string]$StackName = "strictops-cross-account-role"
    )

    $TemplateUrl = "https://raw.githubusercontent.com/strictops/strictops-setup/main/aws/cross-account-role.yaml"

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "  StrictOps IAM Role Setup" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  Region:            " -NoNewline; Write-Host $Region -ForegroundColor Yellow
    Write-Host "  Role Name:         " -NoNewline; Write-Host $RoleName -ForegroundColor Yellow
    Write-Host "  External ID:       " -NoNewline; Write-Host $ExternalId -ForegroundColor Yellow
    Write-Host "  StrictOps Account: " -NoNewline; Write-Host $StrictOpsAccountId -ForegroundColor Yellow
    Write-Host ""

    # Check for AWS CLI
    Write-Host "[1/3]" -ForegroundColor Blue -NoNewline
    Write-Host " Checking AWS credentials..."

    try {
        $identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
        if (-not $identity) {
            throw "Not authenticated"
        }
        Write-Host "      Logged in to AWS account: " -NoNewline
        Write-Host $identity.Account -ForegroundColor Green
    }
    catch {
        Write-Host "Error: AWS credentials not configured" -ForegroundColor Red
        Write-Host "Run 'aws configure' or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        return
    }

    # Download and deploy CloudFormation template
    Write-Host "[2/3]" -ForegroundColor Blue -NoNewline
    Write-Host " Deploying CloudFormation stack..."
    Write-Host "      Downloading template from GitHub..."

    $TempFile = [System.IO.Path]::GetTempFileName() + ".yaml"
    try {
        Invoke-WebRequest -Uri $TemplateUrl -OutFile $TempFile -UseBasicParsing
    }
    catch {
        Write-Host "Error: Failed to download template" -ForegroundColor Red
        return
    }

    Write-Host "      Creating/updating stack '$StackName'..."

    $deployResult = aws cloudformation deploy `
        --capabilities CAPABILITY_NAMED_IAM `
        --stack-name $StackName `
        --template-file $TempFile `
        --parameter-overrides `
            "RoleName=$RoleName" `
            "ExternalId=$ExternalId" `
            "StrictOpsAccountId=$StrictOpsAccountId" `
        --region $Region `
        --no-fail-on-empty-changeset 2>&1

    Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: CloudFormation deployment failed" -ForegroundColor Red
        Write-Host $deployResult
        return
    }

    Write-Host "      Stack deployed " -NoNewline
    Write-Host "successfully" -ForegroundColor Green

    # Get the Role ARN
    Write-Host "[3/3]" -ForegroundColor Blue -NoNewline
    Write-Host " Retrieving Role ARN..."

    $RoleArn = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query "Stacks[0].Outputs[?OutputKey=='StrictOpsRoleArn'].OutputValue | [0]" `
        --output text `
        --region $Region

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Copy this Role ARN and paste it in StrictOps:"
    Write-Host ""
    Write-Host "  $RoleArn" -ForegroundColor Yellow
    Write-Host ""

    # Copy to clipboard
    $RoleArn | Set-Clipboard
    Write-Host "  (Copied to clipboard)" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "StrictOps setup script loaded. Run:" -ForegroundColor Cyan
Write-Host ""
Write-Host '  Setup-StrictOpsRole -ExternalId "<YOUR_EXTERNAL_ID>" -StrictOpsAccountId "<STRICTOPS_ACCOUNT>"' -ForegroundColor Yellow
Write-Host ""
