# Terraform Data Sources

## Overview

This project demonstrates how to use Terraform **Data Sources** to retrieve information from both local files and existing AWS resources.

Unlike resources, data sources are **read-only**. They allow Terraform to fetch existing information that can be used elsewhere in the configuration without creating or modifying infrastructure.

---

## Examples Covered

### 1. Local File Data Source

The `local_file` data source reads the contents of a local file (`demo.txt`) and exposes it as an output.

```terraform
data "local_file" "example" {
  filename = "${path.module}/demo.txt"
}

output "file_content" {
  value = data.local_file.example.content
}
```

This example demonstrates how Terraform can read local files without requiring any cloud provider.

---

### 2. AWS AMI Data Source

The `aws_ami` data source retrieves the **latest Ubuntu 24.04 LTS AMI** published by Amazon.

```terraform
data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

The retrieved AMI ID is then used while creating an EC2 instance.

```terraform
resource "aws_instance" "web" {
  ami           = data.aws_ami.my_ami.id
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}
```

Using a data source avoids hardcoding the AMI ID and ensures that the latest matching image is selected automatically.

---

### 3. AWS EC2 Instance Data Source

The `aws_instance` data source retrieves information about an **existing EC2 instance** based on the specified filter.

```terraform
data "aws_instance" "example" {
  filter {
    name   = "tag:Team"
    values = ["Production"]
  }
}
```

This data source searches for an EC2 instance with the tag:

```
Team = Production
```

**Note:** This data source does **not** create an EC2 instance. It only reads information about an existing one. If no matching instance is found, Terraform returns an error.

---

## Enabling Terraform Logs

Terraform supports detailed internal logging (provider calls, HTTP requests, plan/apply internals) via the `TF_LOG` and `TF_LOG_PATH` environment variables.

> **Note:** These are shell environment variables, not Terraform `variable` blocks. Terraform's logging engine does not read `.tf` or `.tfvars` files directly — this project uses a small wrapper script (`run.sh`) to bridge the two.

### Log Levels

| Level   | Verbosity                    |
|---------|-------------------------------|
| `TRACE` | Most detailed (recommended for debugging) |
| `DEBUG` | Detailed                      |
| `INFO`  | General information            |
| `WARN`  | Warnings only                  |
| `ERROR` | Errors only                    |

### Usage

Instead of calling `terraform` directly, use the provided `run.sh` wrapper:

```bash
chmod +x run.sh
./run.sh plan
./run.sh apply
```

`run.sh` will:
1. Read `tf_log` and `tf_log_file` values from `terraform.tfvars` (if present)
2. Fall back to defaults (`TRACE` and `terraform.txt`) if those keys are missing
3. Export them as `TF_LOG` / `TF_LOG_PATH` for the duration of the run
4. Run the Terraform command you passed in (`plan`, `apply`, `destroy`, etc.)
5. Unset the variables afterward so logging doesn't leak into other terminal commands

### Configuring log settings

Optionally set these in `terraform.tfvars` to override the script defaults:

```hcl
tf_log      = "TRACE"
tf_log_file = "terraform.txt"
```

### Manual alternative (without the script)

```bash
export TF_LOG=TRACE
export TF_LOG_PATH=./terraform.txt

terraform apply

unset TF_LOG
unset TF_LOG_PATH
```

### Important

- Log files can contain sensitive data (resource details, provider internals) — `terraform.txt` / `*.log` are excluded via `.gitignore` and should never be committed.
- `tf_log` / `tf_log_file` are plain key-value entries in `terraform.tfvars` used only by `run.sh` — they are **not** Terraform `variable` blocks and have no effect if referenced inside `.tf` resource/provider configuration.