#--------------------------------------------------------------------------------
# 8. DynamoDB, AWS KMS Key & IRSA Role for Vault
#--------------------------------------------------------------------------------

# 1. AWS KMS Key for Vault Auto-Unseal
resource "aws_kms_key" "vault_unseal" {
  description             = "KMS Key for HashiCorp Vault Auto-Unseal"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-vault-kms-unseal"
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${var.cluster_name}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# 2. DynamoDB Table for HashiCorp Vault Storage
resource "aws_dynamodb_table" "vault_storage" {
  name         = "${var.cluster_name}-vault-backend"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Path"
  range_key    = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.cluster_name}-vault-storage"
  }
}

# 3. IAM Policy for DynamoDB Access & AWS KMS Auto-Unseal
resource "aws_iam_policy" "vault_policy" {
  name        = "${var.cluster_name}-vault-policy"
  description = "Allows Vault Fargate Pods to access DynamoDB and AWS KMS for Auto-Unseal"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.vault_storage.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.vault_unseal.arn
      }
    ]
  })
}

# 4. IRSA Role for Vault Service Account
resource "aws_iam_role" "vault_irsa" {
  name = "${var.cluster_name}-vault-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:vault:vault",
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vault_policy_attach" {
  policy_arn = aws_iam_policy.vault_policy.arn
  role       = aws_iam_role.vault_irsa.name
}

# --------------------------------------------------------------------------------
#  Deploy HashiCorp Vault with DynamoDB Storage & KMS Auto-Unseal via Helm
# --------------------------------------------------------------------------------

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "vault"
  create_namespace = true

  values = [
    <<-EOF
    server:
      enabled: true
      
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${aws_iam_role.vault_irsa.arn}"
      
      dataStorage:
        enabled: false

      ha:
        enabled: true
        config: |
          ui = true
          
          listener "tcp" {
            tls_disable     = 1
            address         = "[::]:8200"
            cluster_address = "[::]:8201"
          }

          storage "dynamodb" {
            ha_enabled = "true"
            region     = "ap-south-1"
            table      = "${aws_dynamodb_table.vault_storage.name}"
          }

          seal "awskms" {
            region     = "ap-south-1"
            kms_key_id = "${aws_kms_key.vault_unseal.key_id}"
          }

    injector:
      enabled: true
    EOF
  ]

  depends_on = [
    aws_eks_fargate_profile.vault,
    aws_dynamodb_table.vault_storage,
    aws_kms_key.vault_unseal,
    aws_iam_role_policy_attachment.vault_policy_attach
  ]
}