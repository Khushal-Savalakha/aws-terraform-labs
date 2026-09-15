# Provider Aliasing in Terraform

This module demonstrates how to deploy infrastructure into **two distinct AWS regions** (`us-east-1` and `ap-south-1`) from a single Terraform configuration using **provider aliases**, with remote state stored in S3.

---

## File Structure

```
.
├── backend.tf                   # S3 remote backend + native state locking
├── providers.tf                 # Default (unaliased) provider configuration
├── main.tf                      # Aliased providers and module invocation
├── variables.tf                 # Input variables
├── outputs.tf                   # Output definitions
├── sample.tfvars                # Sample variable definitions
└── modules/
    └── network/
        └── security-group.tf    # Module consuming the aliased providers
```

---

## Prerequisites

### 1. AWS Credentials

Terraform's S3 backend (`backend.tf`) does **not** read `var.aws_access_key` / `var.aws_secret_key` — those variables are only used by the `provider "aws"` blocks in `main.tf` / `providers.tf`. The backend is initialized *before* Terraform evaluates any variables, so credential values cannot be interpolated there (`Error: Variables not allowed`).

Instead, the S3 backend resolves credentials from the standard AWS credential chain — most commonly environment variables. Export them in your shell **before** running any `terraform` command:

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="ap-south-1"   # optional, backend.tf already sets region explicitly
```

Verify the credentials are valid before touching Terraform:

```bash
aws sts get-caller-identity
```

If this fails, fix your exported values first — Terraform will surface the same underlying error (`InvalidClientTokenId`, `SignatureDoesNotMatch`, etc.) during `terraform init`.

> **Note:** Single-quote secret values (`export AWS_SECRET_ACCESS_KEY='...'`) to avoid shell interpretation of special characters like `/` or `+`, and double-check there's no trailing whitespace/newline when copy-pasting.

### 2. IAM Permissions

The IAM identity behind the exported credentials must be permitted to read/write the state object and its lock file under the exact prefix used in `backend.tf`. See [Backend Configuration](#backend-configuration-remote-state) below for how the `key` value must align with your IAM policy's resource prefix.

---

## Backend Configuration (Remote State)

State is stored remotely in S3 with Terraform's native S3 locking (no separate DynamoDB table required).

`backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-logs-007"
    key          = "production.tfstate/ap-south-1/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
```

* `bucket` — S3 bucket holding all environment state files.
* `key` — object path for this environment's state file. **This must match the prefix your IAM policy grants access to.** For example, if your policy scopes `s3:GetObject`/`s3:PutObject` to `production.tfstate/ap-south-1/*`, the `key` must live under that same prefix (e.g. `production.tfstate/ap-south-1/terraform.tfstate`) — a mismatched key (such as a bare `production.tfstate`) will fail with `403 Forbidden` even when credentials are valid.
* `use_lockfile` — enables Terraform's native S3 lockfile mechanism. This creates a `<key>.tflock` object alongside the state file during operations, so any IAM policy statement scoping lock access (e.g. `*.tflock` under the same prefix) must also match this path.

### Backend blocks accept literal values only

`backend "s3" {}` cannot reference `var.*`, locals, or any other Terraform expression — only hardcoded strings. If you need to inject credentials or other dynamic values into the backend at init time, use one of:

```bash
# Partial backend config file (not committed to git)
terraform init -backend-config=backend.hcl

# Or individual flags
terraform init -backend-config="access_key=..." -backend-config="secret_key=..."
```

For this setup, credentials are supplied via environment variables instead (see [Prerequisites](#prerequisites)), which is the simpler and more common pattern.

### Changing the backend configuration later

If you ever modify `backend.tf` (e.g. changing the `key`, `bucket`, or `region`) after having already run `terraform init` once, Terraform will detect the drift and stop with:

```
Error: Backend configuration changed
```

Resolve it with one of:

```bash
terraform init -reconfigure     # adopt new config, do NOT migrate existing state
terraform init -migrate-state   # adopt new config AND copy existing state to the new location
```

Use `-reconfigure` if no real state exists yet at the old location (e.g. previous attempts failed with permission errors). Use `-migrate-state` only if you have real state data at the old path that you need preserved.

---

## How Provider Aliasing Works

### 1. Default (Unaliased) vs. Aliased Providers

Normally, a `provider "aws" {}` block without an `alias` argument acts as the default provider configuration for that scope. Adding the `alias` argument creates an additional instance of that same provider under a distinct reference name.

In `providers.tf`:

```hcl
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

Because this `provider "aws"` block does **not** have an `alias` argument, Terraform treats it as the default (unaliased) provider for that module level.

#### How Provider Selection Works

* **Implicit Default Matching:** Any resource in the same module (e.g., `resource "aws_security_group" "example" {}`) that does not explicitly include a `provider = ...` argument will automatically default to using this unaliased `provider "aws"` block.
* **Unaliased vs. Aliased:**
  * **No alias defined:** Becomes the default instance for that provider type (`aws`).
  * **`alias = "name"` defined:** Creates an alternate configuration (`aws.name`) that must be explicitly called via `provider = aws.name`.

#### Clarifying Scope: Root Module vs. Child Modules

To clear up the point about where this provider lives:

* **In the Root Module:** If this unaliased block lives in your root `providers.tf`, it serves as the default provider for all root-level resources.
* **In a Child Module:** Child modules inherit provider configurations from the root module unless explicitly overridden. If a child resource has no `provider` argument specified, it looks for the unaliased `aws` provider passed down from the root.

---

### 2. Declaring Aliased Providers

In `main.tf`, alternate instances of the `aws` provider are defined using the `alias` argument:

```hcl
provider "aws" {
  alias      = "virginia"
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "mumbai"
  region     = "ap-south-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

Terraform tracks three distinct `aws` provider instances for this configuration:

| Reference        | Region                                  | Declared in    |
|-------------------|------------------------------------------|-----------------|
| `aws` (default)   | `var.aws_region` (default `ap-south-1`)  | `providers.tf` |
| `aws.virginia`    | `us-east-1`                              | `main.tf`      |
| `aws.mumbai`      | `ap-south-1`                             | `main.tf`      |

---

### 3. Passing Aliased Providers to Child Modules

Child modules **do not** automatically inherit provider aliases from parent modules. You must explicitly pass them via the `providers` map argument during the module call.

In `main.tf`:

```hcl
module "security-group" {
  source = "./modules/network"

  providers = {
    aws.virginia = aws.virginia
    aws.mumbai   = aws.mumbai
  }
}
```

#### Mapping Syntax

`providers = { <module_alias_name> = <root_provider_instance> }`

*Note: The module alias name on the left side does not have to match the root alias name on the right side.*

---

### 4. Declaring Configuration Aliases in the Child Module

Child modules must declare any expected provider aliases using the `configuration_aliases` argument within their `required_providers` block.

In `modules/network/security-group.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.virginia, aws.mumbai]
    }
  }
}
```

This declaration forms a strict contract: Terraform will raise an error at plan time if a caller fails to pass provider configurations matching `aws.virginia` and `aws.mumbai`.

---

### 5. Assigning Providers to Resources

Inside the module, resources specify which provider instance to use via the `provider` meta-argument:

```hcl
resource "aws_security_group" "dev" {
  provider = aws.mumbai
  name     = "dev-sg"
}

resource "aws_security_group" "prod" {
  provider = aws.virginia
  name     = "prod-sg"
}
```

* `aws_security_group.dev` deploys to `ap-south-1`.
* `aws_security_group.prod` deploys to `us-east-1`.

---

## End-to-End Resolution Flow

```
Root Configuration (providers.tf, main.tf)
│
├── provider "aws" (default: ap-south-1) ─────────────► Used by unaliased root resources
│
├── provider "aws" alias="virginia" (us-east-1) ──┐
├── provider "aws" alias="mumbai"   (ap-south-1) ──┤
│                                                   │
└── module "security-group"                        │
      │                                             │
      └── providers = {                             │
            aws.virginia = aws.virginia ────────────┼── (Forwarded)
            aws.mumbai   = aws.mumbai   ────────────┘
          }
        │
        ▼
Child Module (modules/network/security-group.tf)
│
├── required_providers {
│     aws { configuration_aliases = [aws.virginia, aws.mumbai] }
│   }
│
├── resource "aws_security_group" "dev"  { provider = aws.mumbai   }  ──► Target: ap-south-1
└── resource "aws_security_group" "prod" { provider = aws.virginia }  ──► Target: us-east-1
```

---

## Getting Started

```bash
# 1. Export credentials (used by both the S3 backend and the aws providers)
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."

# 2. Verify they work
aws sts get-caller-identity

# 3. Initialize Terraform (downloads providers, configures S3 backend)
terraform init

# 4. Review the plan
terraform plan -var-file="sample.tfvars"

# 5. Apply
terraform apply -var-file="sample.tfvars"
```

---

## Core Rules & Best Practices

1. **Explicit Forwarding**: Aliased providers do not cross module boundaries automatically; explicit forwarding via the `providers` module map is required.
2. **Explicit Contracts**: Child modules relying on multiple provider instances must declare them in `configuration_aliases`.
3. **Multi-Account Deployment**: To target distinct AWS accounts instead of just regions, define separate credentials within each aliased `provider` block (e.g., using `aws_access_key_virginia` and `aws_access_key_mumbai`).
4. **Backend Credentials Are Separate From Provider Credentials**: The `backend "s3" {}` block cannot use `var.*` values. Supply backend credentials via environment variables, `-backend-config`, or an AWS CLI `profile` — never by referencing Terraform variables directly in the block.
5. **Backend `key` Must Match IAM Policy Prefixes**: Keep the state file's `key` (and its derived `.tflock` path) aligned with whatever prefix your IAM policy grants `s3:GetObject`/`s3:PutObject`/`s3:ListBucket` access to, to avoid `403 Forbidden` errors.