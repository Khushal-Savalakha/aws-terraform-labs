# Output, Variable Types & Cross-Referencing in Terraform

This lab demonstrates how to use **output values**, **variable types**, and **cross-referencing resource attributes** in Terraform with AWS resources (EC2, EIP, Security Group, IAM User).

## Files

- `provider.tf` – AWS provider configuration
- `variables.tf` – Input variable definitions with type constraints
- `cross-reference-attributes.tf` – Resources demonstrating attribute cross-referencing and outputs
- `terraform.tfvars` – Variable values for this environment
- `sample.terraform.tfvars` – Example/template for variable values

## Variable Precedence (Highest to Lowest)

Terraform loads variable values from multiple sources. When the same variable is defined in more than one place, the following order decides which value wins:

| Priority | Source |
|----------|--------|
| 1 (Highest) | `-var` command-line option |
| 2 | `-var-file` files (later files override earlier ones) |
| 3 | `*.auto.tfvars` and `*.auto.tfvars.json` |
| 4 | `terraform.tfvars` and `terraform.tfvars.json` |
| 5 | Environment variables `TF_VAR_name` |
| 6 (Lowest) | Default value in the variable block |

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
Automatically loaded — no flag and no fixed file name required. Any file ending in `.auto.tfvars` is picked up automatically, e.g. `prod.auto.tfvars`, `region.auto.tfvars`:

`prod.auto.tfvars`
```hcl
aws_region = "ap-south-1"
```

```bash
terraform apply
```

**4. `terraform.tfvars` / `terraform.tfvars.json`**
Automatically loaded, but the file name must be exactly `terraform.tfvars`:

`terraform.tfvars`
```hcl
instance_count = 2
```

```bash
terraform apply
```

> **Note:** `terraform.tfvars` requires that exact file name to be auto-loaded. A custom name like `prod.tfvars` is **not** auto-loaded and must be explicitly passed using `-var-file="prod.tfvars"`. `*.auto.tfvars` removes this restriction — any name + `.auto.tfvars` suffix (e.g. `prod.auto.tfvars`, `staging.auto.tfvars`) is auto-loaded without needing `-var-file`.

**5. Environment variables `TF_VAR_name`**
```bash
export TF_VAR_aws_region="us-west-2"
export TF_VAR_instance_count=3
terraform apply
```

**6. Default value in the variable block (lowest priority)**
```hcl
variable "instance_type" {
  default = "t2.micro"
  type    = string
}
```
Used only if no other source provides a value:
```bash
terraform apply
```

## Variable Types Used

- `string` – e.g., `aws_access_key`, `aws_secret_key`, `aws_region`, `username`, `ami`, `instance_type`
- `number` – e.g., `instance_count`
- `list(string)` – e.g., `security_groups`
- `map(string)` – e.g., `ec2_tags`

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
  instance_type   = var.instance_type
  key_name        = "Terraform"
  security_groups = concat(var.security_groups, [aws_security_group.allow_tls.name])
  tags            = var.ec2_tags
}
```

`terraform.tfvars`
```hcl
ec2_tags = {
  Name        = "web-server"
  Environment = "production"
  Project     = "terraform-labs"
  Owner       = "Khushal"
  ManagedBy   = "Terraform"
}
```

## Output Values

Outputs expose useful information after `terraform apply`, such as resource IDs or computed attributes, without needing to inspect the state file manually.

```hcl
output "public-ip" {
  value = aws_eip.web_eip.public_ip
}
```

This prints the Elastic IP's public IP address after apply — useful for quickly referencing or feeding into scripts/other configs.

## Cross-Referencing Resource Attributes

Cross-referencing means using one resource's attribute as input to another resource, creating an implicit dependency Terraform resolves automatically.

Examples in this lab:

- `aws_vpc_security_group_ingress_rule.allow_tls_ipv4` uses `aws_eip.web_eip.public_ip` to dynamically set the allowed CIDR.
- `aws_security_group.allow_tls.id` is referenced as the `security_group_id` for the ingress rule.
- `aws_instance.web` uses `concat()` to combine `var.security_groups` with `aws_security_group.allow_tls.name`.
- `aws_eip_association.eip_assoc` links `aws_instance.web[0].id` with `aws_eip.web_eip.id`.

## Usage

```bash
terraform init
terraform plan
terraform apply
```
