# 🚀 AWS EC2 Instance Provisioning with Terraform

![Terraform](https://img.shields.io/badge/Terraform-v1.x-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazonaws)
![IaC](https://img.shields.io/badge/IaC-Infrastructure--as--Code-blue)

Provision one or more AWS EC2 instances using Terraform — a beginner-friendly Infrastructure as Code (IaC) project.

---

## 📁 Project Structure

```
aws-ec2-provisioning/
├── main.tf                  # EC2 instance resource definition
├── provider.tf              # AWS provider configuration
├── vars.tf                  # Input variables (AMI, instance type, count)
├── aws-config               # AWS region config (git-ignored)
├── aws-credentials          # AWS access keys (git-ignored)
├── sample.aws-config        # Template for aws-config
└── sample.aws-credentials   # Template for aws-credentials
```

---

## ✅ Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.15.5 installed
- An active [AWS account](https://aws.amazon.com/free/)
- AWS IAM user with **EC2 full access** permissions
- An existing AWS **Key Pair** named `Terraform` in your region
- An existing **Security Group** named `launch-wizard-1`

---

## ⚙️ Setup

**1. Clone the repository**
```bash
git clone https://github.com/Khushal-Savalakha/aws-terraform-labs.git
cd aws-ec2-provisioning
```

**2. Configure AWS credentials**
```bash
cp sample.aws-config aws-config
cp sample.aws-credentials aws-credentials
```

**3. Edit `aws-credentials` with your actual keys**
```ini
[default]
aws_access_key_id     = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

**4. Edit `aws-config` with your preferred region**
```ini
[default]
region = us-east-1
output = json
```

---

## 🔧 Usage

### Initialize Terraform
```bash
terraform init
```

### Preview Changes (Dry Run)
```bash
terraform plan
```

### Apply — Create Infrastructure
```bash
terraform apply
```
> Type `yes` when prompted to confirm.

### Destroy — Delete All Resources
```bash
terraform destroy
```

### Destroy a Specific Resource
```bash
terraform destroy -target aws_instance.AWSServer
```

---

## 📦 Variables

Customize the deployment by editing `vars.tf` or passing values via CLI flags.

| Variable         | Default                 | Description                          |
|------------------|-------------------------|--------------------------------------|
| `ami`            | `ami-0d5e8769671b48387` | Amazon Machine Image ID (us-east-1)  |
| `instance_type`  | `t2.micro`              | EC2 instance size (Free Tier eligible)|
| `instance_count` | `1`                     | Number of EC2 instances to provision |



---

## 🌐 Resources Created

- `aws_instance.AWSServer` — EC2 instance(s) tagged as `EC2 VM - {index}`

