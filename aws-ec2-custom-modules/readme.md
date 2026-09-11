# 🚀 AWS EC2 Custom Module with Elastic IP

[![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

A reusable, production-ready **Terraform module** that provisions an AWS EC2 instance and attaches a static **Elastic IP (EIP)** to it — built with a clean root/child module structure so it can be dropped into any Terraform project.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Project Structure](#-project-structure)
- [How It Works](#-how-it-works)
  - [1. Passing Values from Root to Module](#1-passing-values-from-root-to-module)
  - [2. Retrieving Module Outputs in Root](#2-retrieving-module-outputs-in-root)

---

## 🧭 Overview

This repository demonstrates Terraform **module composition** — separating reusable infrastructure logic (the EC2 instance) from the root configuration that consumes it. The root module also allocates and associates an **Elastic IP**, giving the instance a stable public IP address that persists across reboots.

**Key concepts covered:**
- Root-to-module variable passing
- Module output referencing
- Clean separation of concerns between root and child modules
- Reusable EC2 provisioning pattern

---

## 📁 Project Structure

```text
aws-ec2-custom-modules/
├── main.tf              # Root module calling the EC2 module and allocating an EIP
├── variables.tf         # Root input variables definition
├── outputs.tf           # Root outputs exposing values to the terminal
├── providers.tf         # Terraform version and AWS provider configuration
├── sample.tfvars        # Sample file providing values to root variables
└── modules/
    └── ec2-instance/
        ├── main.tf       # EC2 resource definition
        ├── variables.tf  # Module input variables definition
        └── outputs.tf    # Module output definitions
```

---

## ⚙️ How It Works

### 1. Passing Values from Root to Module

Values flow from the root configuration into a child module through the arguments inside a `module` block. You can pass **direct/hardcoded values** or **root-level variables** (`var.xxx`).

> **Internally:** Terraform reads the arguments defined in the root `main.tf`, matches them against the `variables.tf` declared inside the child module, and injects them into the module's scope — making them accessible via `var.` inside that module.

#### Step A — Declare variables inside the module
`modules/ec2-instance/variables.tf`

```hcl
variable "ami" {
  type = string
}

variable "aws_region" {
  type = string
}
```

#### Step B — Consume the variables inside the module
`modules/ec2-instance/main.tf`

```hcl
resource "aws_instance" "ec2_instance" {
  ami    = var.ami          # Accepting and using the passed variable
  region = var.aws_region   # Accepting and using the passed variable
}
```

#### Step C — Pass values from the root module
`main.tf`

```hcl
module "ec2-instance" {
  source     = "./modules/ec2-instance"
  ami        = "ami-090d68841c2a28756"  # Direct/hardcoded value
  aws_region = var.aws_region           # Root-level variable
}
```

---

### 2. Retrieving Module Outputs in Root

Child modules are isolated by design — their internal resource attributes aren't visible outside the module. To surface a value, you must explicitly **define an output inside the module**, then **reference it from the root** using the module's name.

Since the module block is named `module "ec2-instance"`, its data is accessed via:

```hcl
module.ec2-instance.<output_name>
```

#### Step A — Expose the value inside the module
`modules/ec2-instance/outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.ec2_instance[0].id
}
```

#### Step B — Capture it at the root level
`outputs.tf`

```hcl
output "instance_id" {
  value = module.ec2-instance.instance_id
}
```

This prints the instance ID in your terminal after `terraform apply` completes. ✅