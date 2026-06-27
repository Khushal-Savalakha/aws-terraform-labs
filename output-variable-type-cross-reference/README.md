# Output, Variable Types, Conditional Expressions & Cross-Referencing in Terraform

This lab demonstrates how to use **output values**, **variable types**, **conditional expressions**, and **cross-referencing resource attributes** in Terraform with AWS resources (EC2, EIP, Security Group, IAM User).

## Files

* `provider.tf` – AWS provider configuration
* `variables.tf` – Input variable definitions with type constraints
* `cross-reference-attributes.tf` – Resources demonstrating conditional expressions, attribute cross-referencing, and outputs
* `terraform.tfvars` – Variable values for this environment
* `sample.terraform.tfvars` – Example/template for variable values

---

## Variable Precedence (Highest to Lowest)

Terraform loads variable values from multiple sources. When the same variable is defined in more than one place, the following order decides which value wins:

| Priority    | Source                                                |
| ----------- | ----------------------------------------------------- |
| 1 (Highest) | `-var` command-line option                            |
| 2           | `-var-file` files (later files override earlier ones) |
| 3           | `*.auto.tfvars` and `*.auto.tfvars.json`              |
| 4           | `terraform.tfvars` and `terraform.tfvars.json`        |
| 5           | Environment variables `TF_VAR_name`                   |
| 6 (Lowest)  | Default value in the variable block                   |

### Command Examples for Each Source

**1. `-var` (highest priority)**

```bash
terraform apply -var="instance_type=t3.micro" -var="aws_region=us-east-1"
```

**2. `-var-file` (later files override earlier ones)**

```bash
terraform apply -var-file="dev.tfvars" -var-file="prod.tfvars"
```

**3. `*.auto.tfvars` / `*.auto.tfvars.json`**

Automatically loaded—no flag and no fixed file name required.

```hcl
aws_region = "ap-south-1"
```

```bash
terraform apply
```

**4. `terraform.tfvars` / `terraform.tfvars.json`**

Automatically loaded only when the filename is exactly `terraform.tfvars`.

```hcl
instance_count = 2
```

```bash
terraform apply
```

> **Note:** `terraform.tfvars` requires that exact filename to be auto-loaded. Custom names (e.g., `prod.tfvars`) must be passed using `-var-file`. Files ending with `.auto.tfvars` are automatically loaded regardless of their prefix.

**5. Environment variables**

```bash
export TF_VAR_aws_region="us-west-2"
export TF_VAR_instance_count=3
terraform apply
```

**6. Default value**

```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
```

Used only if no other source provides a value.

---

# Variable Types Used

* `string` – `aws_access_key`, `aws_secret_key`, `aws_region`, `username`, `ami`, `environment`, `prod_instance_type`, `dev_instance_type`
* `number` – `instance_count`
* `list(string)` – `security_groups`
* `map(string)` – `ec2_tags`

### `map(string)` Example

```hcl
variable "ec2_tags" {
  type = map(string)
}
```

```hcl
resource "aws_instance" "web" {
  count           = var.instance_count
  ami             = var.ami
  instance_type   = var.environment == "production" ? var.prod_instance_type : var.dev_instance_type
  key_name        = "Terraform"
  security_groups = concat(var.security_groups, [aws_security_group.allow_tls.name])
  tags            = var.ec2_tags
}
```

`terraform.tfvars`

```hcl
environment = "development"

prod_instance_type = "t3.medium"
dev_instance_type  = "t2.micro"

ec2_tags = {
  Name        = "web-server"
  Environment = "production"
  Project     = "terraform-labs"
  Owner       = "Khushal"
  ManagedBy   = "Terraform"
}
```

---

# Conditional Expressions

Terraform supports conditional (ternary) expressions to choose a value based on a condition.

**Syntax**

```hcl
condition ? true_value : false_value
```

In this lab:

```hcl
instance_type = var.environment == "production" ? var.prod_instance_type : var.dev_instance_type
```

This means:

* If `environment` is `"production"`, Terraform uses `prod_instance_type`.
* Otherwise, Terraform uses `dev_instance_type`.

Equivalent logic:

```text
if environment == "production"
    instance_type = prod_instance_type
else
    instance_type = dev_instance_type
```

This makes your infrastructure more reusable, allowing the same Terraform configuration to deploy different instance types for development and production environments.

---

# Output Values

Outputs expose useful information after `terraform apply`, such as resource IDs or computed attributes, without manually inspecting the Terraform state.

```hcl
output "public-ip" {
  value = aws_eip.web_eip.public_ip
}
```

Example output:

```text
Outputs:

public-ip = "13.233.xxx.xxx"
```

---

# Cross-Referencing Resource Attributes

Cross-referencing means using one resource's attribute as the input to another resource. Terraform automatically creates the required dependency graph.

Examples in this lab:

* `aws_vpc_security_group_ingress_rule.allow_tls_ipv4` uses `aws_eip.web_eip.public_ip` to build the allowed CIDR.
* `aws_security_group.allow_tls.id` is referenced by the ingress rule.
* `aws_instance.web` combines existing security groups with the newly created one using `concat()`.
* `aws_eip_association.eip_assoc` associates the Elastic IP with `aws_instance.web[0].id`.

---

# Usage

```bash
terraform init
terraform plan
terraform apply
```