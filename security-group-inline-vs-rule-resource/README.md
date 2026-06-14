# Terraform AWS Security Group: Inline Rules vs Rule Resources

This repository demonstrates two approaches for managing AWS Security Group rules in Terraform:

* **Inline Rules (Legacy Approach)**
* **Standalone Rule Resources (Recommended Approach)**

The goal is to understand how Terraform manages Security Group rules, state, and drift detection.

## Project Structure

```text
.
├── aws-security-group-inline-rules.tf
├── aws-security-group-rule-resources.tf
├── provider.tf
├── variables.tf
├── sample.terraform.tfvars
└── README.md
```

### Files

| File                                   | Purpose                                          |
| -------------------------------------- | ------------------------------------------------ |
| `aws-security-group-inline-rules.tf`   | Security Group using inline ingress/egress rules |
| `aws-security-group-rule-resources.tf` | Security Group using standalone rule resources   |
| `provider.tf`                          | AWS provider configuration                       |
| `variables.tf`                         | Input variables                                  |
| `sample.terraform.tfvars`              | Example variable values                          |
| `README.md`                            | Project documentation                            |

---

## Approach 1: Inline Rules

```hcl
resource "aws_security_group" "allow_tls" {
  ingress { ... }
  egress  { ... }
}
```

### Characteristics

* Security Group and rules are managed as a single Terraform resource.
* Simple and easy for small projects.
* Less granular state management.
* Considered a legacy approach.

---

## Approach 2: Standalone Rule Resources

```hcl
resource "aws_security_group" "firewall" {}

resource "aws_vpc_security_group_ingress_rule" "http" {}

resource "aws_vpc_security_group_egress_rule" "all" {}
```

### Characteristics

* Each rule is managed as an independent Terraform resource.
* Better state management and drift detection.
* Easier troubleshooting and team collaboration.
* Recommended for modern Terraform projects.

---

## What is Drift?

Drift occurs when AWS infrastructure is modified outside Terraform.

Example:

```text
Terraform:
Port 22 should exist

AWS:
Port 22 was manually deleted

Result:
Drift Detected
```

Terraform detects drift during:

```bash
terraform plan
```

and proposes changes to restore the desired state.

---

## Comparison

| Feature            | Inline Rules | Rule Resources |
| ------------------ | ------------ | -------------- |
| Simplicity         | ✅            | ⚠️             |
| State Granularity  | ❌            | ✅              |
| Drift Detection    | Good         | Better         |
| Team Collaboration | ❌            | ✅              |
| Production Ready   | ⚠️           | ✅              |
| Recommended Today  | ❌            | ✅              |

---

## Key Takeaway

* **Inline Rules:** Simple, but all rules belong to a single Terraform resource.
* **Rule Resources:** Each rule has its own lifecycle and state entry, making it easier to manage and scale.

For new Terraform projects, prefer:

```hcl
aws_vpc_security_group_ingress_rule
aws_vpc_security_group_egress_rule
```
