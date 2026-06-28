# Output, Variable Types, Conditional Expressions, Terraform Functions & Cross-Referencing in Terraform

This lab demonstrates how to use **output values**, **variable types**, **conditional expressions**, **Terraform built-in functions**, and **cross-referencing resource attributes** in Terraform with AWS resources (EC2, EIP, Security Group, IAM User).

## Files

* `provider.tf` – AWS provider configuration
* `variables.tf` – Input variable definitions with type constraints
* `cross-reference-attributes.tf` – Resources demonstrating conditional expressions, attribute cross-referencing, and outputs
* `function.tf` – Demonstrates Terraform built-in functions such as `file()`
* `iam-user-policy.json` – IAM policy loaded using Terraform's `file()` function
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

# Terraform Functions

Terraform provides many built-in functions for working with strings, collections, dates, files, and more. This lab demonstrates the following functions:

- `file()`
- `lookup()`
- `element()`
- `formatdate()`
- `timestamp()`
- `length()`

---

## `file()` Function

The `file()` function reads the contents of a file and returns it as a string.

### Syntax

```hcl
file(path)
```

Example:

```hcl
resource "aws_iam_user" "this" {
  name = "demo-user"
}

resource "aws_iam_user_policy" "lb_ro" {
  name = "demo-user-policy"
  user = aws_iam_user.this.name

  policy = file("./iam-user-policy.json")
}
```

### Why use `file()`?

- Keeps large JSON files separate from Terraform code.
- Makes IAM policies easier to maintain.
- Improves readability and reusability.
- Can also load shell scripts, certificates, templates, and configuration files.

---

## `lookup()` Function

The `lookup()` function retrieves a value from a map using a key.

### Syntax

```hcl
lookup(map, key, default)
```

The `default` argument is optional.

Example:

```hcl
variable "region" {
  default = "us-east-1"
}

variable "amis" {
  type = map(string)

  default = {
    us-east-1 = "ami-08a0d1e16fc3f61ea"
    us-west-2 = "ami-0b20a6f09484773af"
    ap-south-1 = "ami-0e1d06225679bc1c5"
  }
}

resource "aws_instance" "app-dev" {
  ami = lookup(var.amis, var.region)
}
```

If `var.region` is `"us-east-1"`, Terraform returns:

```text
ami-08a0d1e16fc3f61ea
```

### Why use `lookup()`?

- Retrieves values from maps.
- Useful for selecting region-specific AMIs.
- Prevents writing multiple conditional expressions.

---

## `element()` Function

The `element()` function returns an item from a list using its index.

### Syntax

```hcl
element(list, index)
```

Example:

```hcl
variable "tags" {
  default = [
    "firstec2",
    "secondec2"
  ]
}

resource "aws_instance" "app-dev" {
  count = length(var.tags)

  tags = {
    Name = element(var.tags, count.index)
  }
}
```

Terraform creates:

| EC2 Instance | Name Tag |
|--------------|----------|
| 1 | firstec2 |
| 2 | secondec2 |

### Why use `element()`?

- Retrieves values from a list by index.
- Commonly used with `count.index`.
- Useful when creating multiple resources with different names.

---

## `length()` Function

The `length()` function returns the number of elements in a collection or the number of characters in a string.

### Syntax

```hcl
length(value)
```

Example:

```hcl
count = length(var.tags)
```

If:

```hcl
tags = [
  "firstec2",
  "secondec2"
]
```

Terraform creates:

```text
2 EC2 instances
```

### Why use `length()`?

- Determines how many resources should be created.
- Frequently used with the `count` meta-argument.

---

## `timestamp()` Function

The `timestamp()` function returns the current date and time in UTC using RFC3339 format.

### Syntax

```hcl
timestamp()
```

Example output:

```text
2026-06-28T05:20:31Z
```

This value is commonly passed to other functions such as `formatdate()`.

---

## `formatdate()` Function

The `formatdate()` function converts a timestamp into a human-readable format.

### Syntax

```hcl
formatdate(spec, timestamp)
```

Example:

```hcl
tags = {
  CreationDate = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
}
```

Possible output:

```text
28 Jun 2026 05:20 UTC
```

### Why use `formatdate()`?

- Creates readable timestamps.
- Useful for resource tags.
- Makes infrastructure metadata easier to understand.

---

## Example Combining Multiple Functions

```hcl
resource "aws_instance" "app-dev" {
  ami           = lookup(var.amis, var.region)
  instance_type = "t2.micro"

  count = length(var.tags)

  tags = {
    Name         = element(var.tags, count.index)
    CreationDate = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
  }
}
```

This example demonstrates several Terraform functions working together:

- `lookup()` selects the AMI based on the AWS region.
- `length()` determines how many EC2 instances to create.
- `element()` assigns a different name tag to each instance.
- `timestamp()` generates the current UTC time.
- `formatdate()` converts the timestamp into a readable format for tagging resources.
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
* `aws_iam_user_policy.lb_ro` references `aws_iam_user.this.name` to attach the IAM policy to the created IAM user.

---

# Usage

```bash
terraform init
terraform plan
terraform apply
```
