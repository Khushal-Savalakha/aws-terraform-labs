
# Provider Aliasing in Terraform

This module demonstrates how to deploy infrastructure into **two distinct AWS regions** (`us-east-1` and `ap-south-1`) from a single Terraform configuration using **provider aliases**.

---

## File Structure


```

.
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

| Reference | Region | Declared in |
| --- | --- | --- |
| `aws` (default) | `var.aws_region` (default `ap-south-1`) | `providers.tf` |
| `aws.virginia` | `us-east-1` | `main.tf` |
| `aws.mumbai` | `ap-south-1` | `main.tf` |

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
│                                                 │
└── module "security-group"                       │
      │                                           │
      └── providers = {                           │
            aws.virginia = aws.virginia ──────────┼── (Forwarded)
            aws.mumbai   = aws.mumbai   ──────────┘
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

## Core Rules & Best Practices

1. **Explicit Forwarding**: Aliased providers do not cross module boundaries automatically; explicit forwarding via the `providers` module map is required.
2. **Explicit Contracts**: Child modules relying on multiple provider instances must declare them in `configuration_aliases`.
3. **Multi-Account Deployment**: To target distinct AWS accounts instead of just regions, define separate credentials within each aliased `provider` block (e.g., using `aws_access_key_virginia` and `aws_access_key_mumbai`).