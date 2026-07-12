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