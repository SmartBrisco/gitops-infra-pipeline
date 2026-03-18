# GitOps Infrastructure Pipeline

## Overview

Event-driven GitOps pipeline that provisions multi-cloud infrastructure on every commit to `main` using GitHub Actions and Terraform. Features OPA policy gates, three parallel cloud deployment jobs, multi-channel Slack notifications, and OIDC authentication eliminating all long-lived credentials.

AWS deploys fully on every push. GCP and Azure run the complete security gate pipeline on every commit with infrastructure scaffolded and ready to activate. OPA policy tests run across AWS and GCP before any deployment proceeds.

## Architecture

```
Git Push to Main
        ↓
GitHub Actions Trigger
        ↓
OPA Policy Tests (AWS + GCP)
        ├── tags.rego       - all resources must have managed-by and environment tags
        ├── network.rego    - no SSH open to 0.0.0.0/0 across all clouds
        └── compute.rego    - approved instance types only per cloud
        ↓
Three Parallel Jobs
        ├── AWS Deploy
        │     ├── OIDC Authentication → AWS IAM Role (temporary credentials)
        │     ├── fmt → validate → TFLint → Trivy
        │     ├── Terraform Plan + Apply
        │     │     ├── VPC + Subnet + Internet Gateway + Route Table
        │     │     └── EC2 t2.micro (Amazon Linux 2)
        │     ├── Capture Outputs (Instance ID, Public IP, State)
        │     └── Slack Notifications
        │
        ├── GCP Deploy
        │     ├── fmt → validate → TFLint → Trivy
        │     ├── Terraform Plan (apply disabled - credentials pending)
        │     │     └── VPC + Subnet + Firewall + e2-micro VM (count = 0)
        │     └── Slack Notifications
        │
        └── Azure Deploy
              ├── fmt → validate → TFLint → Trivy
              ├── Terraform Plan (skipped - credentials required)
              │     └── Resource Group + VNet + NSG + Standard_B1s VM (count = 0)
              └── Slack Notifications

All Jobs → #infra-audit (always)
```

## Components

**OPA Policy Gates** run before all cloud deployments using Conftest and custom Rego policies. Unlike Trivy which checks against a vendor-maintained ruleset, OPA enforces organizational policies you define -- required tags, no open SSH, and approved instance types per cloud. Azure OPA steps are scaffolded and ready to activate once credentials are configured.

Azure OPA steps are scaffolded and commented in - activate by uncommenting once credentials are configured.

**GitHub Actions** orchestrates four parallel jobs. Triggered on every push to `main` or manual dispatch via `workflow_dispatch`. Path filtering ensures only commits touching `terraform/**` trigger pipeline runs.

**OIDC Authentication** eliminates long-lived credentials entirely. GitHub Actions requests a JWT token, AWS validates it originated from this specific repository via a registered OIDC Identity Provider, and assumes the designated IAM role for temporary scoped access. The same pattern is scaffolded for GCP Workload Identity Federation and Azure federated credentials.

**Terraform** provisions all infrastructure from scratch per cloud. GCP and Azure resources use a `deploy` boolean variable (`default = false`) with `count = var.deploy ? 1 : 0` on every resource - the full configuration is validated, linted, and security scanned on every commit without making any API calls.

**Security Pipeline Gates** run on all three clouds before any infrastructure changes:
- `terraform fmt` enforces consistent code formatting 
- `terraform validate` catches syntax errors before plan
- `TFLint` identifies cloud-provider-specific issues and deprecated patterns validate won't catch
- `Trivy` scans and detects HIGH and CRITICAL misconfigurations in the infrastructure code itself

**Multi-Channel Slack Notifications** provide real-time visibility per cloud 
- `#infra-deployments` - successful deployments with resource details. Informational, low urgency.
- `#infra-alerts` - failures with direct link to the failed run. Actionable, can be wired to on-call paging without noise from successful runs.
- `#infra-audit` - every run regardless of outcome. Complete immutable audit trail for compliance and incident investigation.

## Repository Structure

```
gitops-infra-pipeline/
├── .github/
│   └── workflows/
│       └── terraform.yml          # OPA gate + three parallel cloud jobs
├── policy/
│   ├── tags.rego                  # Required tag enforcement
│   ├── network.rego               # No open SSH across all clouds
│   └── compute.rego               # Approved instance types per cloud
├── terraform/
│   ├── aws/
│   │   ├── main.tf                # VPC, subnet, security group, EC2
│   │   ├── variables.tf
│   │   ├── outputs.tf             # Instance ID, public IP, state
│   │   └── provider.tf            # AWS provider with skip flags for policy testing
│   ├── gcp/
│   │   ├── main.tf                # VPC, subnet, firewall, compute instance
│   │   ├── variables.tf           # Includes deploy flag (default = false)
│   │   ├── outputs.tf
│   │   └── provider.tf            # Google provider
│   └── azure/
│       ├── main.tf                # Resource group, VNet, NSG, Linux VM
│       ├── variables.tf           # Includes deploy flag (default = false)
│       ├── outputs.tf
│       └── provider.tf            # AzureRM provider
├── screenshots/
├── .gitignore
└── README.md
```

## Prerequisites

### AWS (active)
- AWS account with IAM role configured for GitHub OIDC
- GitHub repository secrets:
  - `AWS_ROLE_ARN`
  - `SLACK_WEBHOOK_DEPLOYMENTS`
  - `SLACK_WEBHOOK_ALERTS`
  - `SLACK_WEBHOOK_AUDIT`
- Slack workspace with three channels and incoming webhooks configured

### GCP (scaffolded - apply disabled)
- GCP account with Workload Identity Federation configured
- GitHub repository secrets when ready to activate:
  - `GCP_WORKLOAD_IDENTITY_PROVIDER`
  - `GCP_SERVICE_ACCOUNT`

### Azure (scaffolded - plan and OPA disabled)
- Azure account with federated credentials configured on a service principal
- GitHub repository secrets when ready to activate:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_SSH_PUBLIC_KEY`

## Setup

### 1. Configure GitHub OIDC in AWS

Create an IAM OIDC Identity Provider:
```
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

Create an IAM Role with this trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/gitops-infra-pipeline:*"
        }
      }
    }
  ]
}
```

Attach policies: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `SecretsManagerReadWrite`

### 2. Configure Slack

Create a Slack app at api.slack.com/apps. Enable Incoming Webhooks. Create three webhooks pointing to:
- `#infra-deployments`
- `#infra-alerts`
- `#infra-audit`

### 3. Add GitHub Secrets

Add to repository Settings → Secrets and variables → Actions:
- `AWS_ROLE_ARN` - ARN of the IAM role created above
- `SLACK_WEBHOOK_DEPLOYMENTS` - webhook URL for deployments channel
- `SLACK_WEBHOOK_ALERTS` - webhook URL for alerts channel
- `SLACK_WEBHOOK_AUDIT` - webhook URL for audit channel

### 4. Deploy

Push any commit to `main` with changes in the `terraform/` directory:
```bash
git add .
git commit -m "feat: trigger infrastructure deployment"
git push origin main
```

### 5. Enabling GCP Apply

1. Configure Workload Identity Federation in GCP
2. Add `GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT` secrets to GitHub
3. Uncomment the auth step in `deploy-gcp` job in `terraform.yml`
4. Uncomment the apply step in `deploy-gcp` job
5. Set `deploy = true` via `-var="deploy=true"` on the plan/apply steps or update the variable default
6. Uncomment the three Azure OPA steps in the `policy-test` job

### 6. Enabling Azure Apply

1. Create a service principal with federated credentials in Azure
2. Add `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_SSH_PUBLIC_KEY` secrets to GitHub
3. Uncomment the auth step in `deploy-azure` job in `terraform.yml`
4. Remove `continue-on-error: true` from the Azure plan step
5. Uncomment the apply step
6. Swap `placeholder-key-replace-when-deploying` in `main.tf` for `var.ssh_public_key`
7. Uncomment the three Azure OPA steps in the `policy-test` job

### 7. Manual Teardown (AWS)

This is a public repository. Automated destroy workflows are not included - see Design Decisions below.

1. EC2 → Instances → select instance → Instance State → Terminate. Wait for terminated status.
2. VPC → Your VPCs → select `gitops-infra-pipeline-vpc` → Actions → Delete VPC. AWS removes all associated resources automatically.

## Screenshots

### Pipeline Flow - OPA Gates + Parallel Cloud Deploys
![Successful Pipeline Run](screenshots/pipeline_success.png)

### Slack Audit Log
![Slack Audit Log](screenshots/slack_audit.png)

### AWS EC2 Console
![AWS EC2 Console](screenshots/aws_ec2.png)

## Design Decisions

**Why OPA/Conftest over just Trivy?**
Trivy scans against a fixed vendor-maintained ruleset. OPA lets you encode your own organizational policies like required tagging standards, approved instance types, or cost governance rules. The two tools complement each other: Trivy catches known misconfigurations, OPA enforces your own standards. Running OPA before deploys means policy violations block infrastructure changes at the pipeline level before any API call is made.

**Why `deploy = false` for GCP and Azure instead of skipping those jobs?**
Running the full security gate pipeline on all three clouds on every commit keeps the code honest. Syntax errors, deprecated patterns, and policy violations get caught immediately even without active accounts. `count = var.deploy ? 1 : 0` means Terraform validates the full resource configuration without provisioning anything. The code stays tested and ready to activate.

**Why three parallel jobs instead of one sequential job?**
Each cloud is independent. Running them in parallel cuts total pipeline time and isolates failures.

**Why OIDC over long-lived access keys?**
Long-lived credentials stored in GitHub secrets are a security liability. OIDC provides temporary scoped credentials valid only for the duration of the workflow run, scoped to this specific repository via the `StringLike` condition on the JWT `sub` claim. Eliminates an entire category of credential exposure risk. 

**Why build all networking explicitly rather than use defaults?**
Building all networking infrastructure explicitly in Terraform ensures consistent, reproducible deployments regardless of account state. Every resource is tagged, tracked, and managed. No dependency on default VPCs or pre-existing resources.

**Why soft_fail on Trivy and OPA network policy?**
The SSH ingress rule is intentionally open for demonstration purposes. In production SSH would be restricted to known CIDR ranges, Trivy `exit-code` would be set to `1`, and the OPA network policy would block the deploy. The current configuration demonstrates the scanning capability without blocking the dev pipeline.

**Why no automated destroy workflow?**
This is a public repository. An automated destroy workflow accessible via `workflow_dispatch` creates an unnecessary attack surface.  In a private repository with branch protection, required reviewers, and environment gates, an automated destroy workflow is recommended.

**Why no Terraform remote state backend?**
For a public portfolio repository, storing Terraform state in S3 risks exposing sensitive values Terraform writes to state. In production, remote state with an S3 backend and DynamoDB locking is required for team environments - DynamoDB state locking prevents concurrent pipeline runs from corrupting the state file.

## Troubleshooting

**OIDC authentication fails**
Verify the trust policy `sub` condition matches your exact GitHub username and repository name. Format must be `repo:USERNAME/REPOSITORY:*` with a colon before the wildcard not a slash.

**Terraform fmt check fails**
Run `terraform fmt -recursive` locally before pushing. The pipeline enforces consistent formatting - unformatted code fails the check.

**OPA policy test fails on tags**
All resources must include both `managed-by` and `environment` tags. Check that your resource tag blocks use exactly those key names - they are case sensitive.

**GCP plan fails with credentials error**
Verify `gcp_credentials` variable contains valid JSON with a `type` field. The default `{"type":"service_account"}` should satisfy provider initialisation without real credentials when `deploy = false`.

**Azure plan fails with auth error**
Azure requires active credentials even for plan. The `continue-on-error: true` flag on the plan step handles this until real credentials are configured. See Enabling Azure Apply above.

**Pipeline triggers on every push**
Verify path filtering in `terraform.yml`. Only commits touching `terraform/**`, `policy/**`, or `.github/workflows/**` should trigger pipeline runs.

**Slack notifications not firing**
Confirm webhook URLs are stored correctly in GitHub secrets with no trailing spaces or quotes. Test webhooks directly with curl before pushing.

**Resources already exist on redeploy**
Without remote state backend, Terraform has no memory of previous deployments. Clean up existing resources manually before redeploying. See Manual Teardown above.

**VPC limit exceeded**
AWS default limit is 5 VPCs per region. Without remote state, previous pipeline runs may have left VPCs behind. Delete unused VPCs in the AWS console before redeploying, or request a limit increase via AWS Service Quotas.

## Part of a Three-Project Platform Engineering Portfolio

- **Project 1** - [Argo Events CI/CD Pipeline](https://github.com/SmartBrisco/argo-event-pipeline) - Event-driven application pipeline with AI-powered failure analysis
- **Project 2** - GitOps Infrastructure Pipeline (this project) - Multi-cloud GitHub Actions and Terraform infrastructure automation with OPA policy gates across AWS, GCP, and Azure
- **Project 3** - [Platform Observability Stack](https://github.com/SmartBrisco/platform-observability) - Unified observability with OpenTelemetry, Jaeger, Prometheus, and Grafana
- **Bootstrap** - [Platform](https://github.com/SmartBrisco/Platform) - One command to spin up the full platform locally in under 10 minutes
