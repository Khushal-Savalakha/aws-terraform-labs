#!/bin/bash
# run.sh — enables Terraform logging with default values

# Defaults (used if not found in terraform.tfvars)
DEFAULT_LOG_LEVEL="TRACE"
DEFAULT_LOG_FILE="terraform.txt"

TFVARS_FILE="terraform.tfvars"

# Try reading from terraform.tfvars, fall back to defaults if missing
if [ -f "$TFVARS_FILE" ]; then
  TF_LOG_LEVEL=$(grep '^tf_log ' "$TFVARS_FILE" | sed -E 's/.*"(.*)"/\1/')
  TF_LOG_FILE=$(grep '^tf_log_file' "$TFVARS_FILE" | sed -E 's/.*"(.*)"/\1/')
fi

export TF_LOG="${TF_LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
export TF_LOG_PATH="${TF_LOG_FILE:-$DEFAULT_LOG_FILE}"

echo "Terraform logging enabled:"
echo "  TF_LOG      = $TF_LOG"
echo "  TF_LOG_PATH = $TF_LOG_PATH"
echo ""

terraform "$@"

unset TF_LOG
unset TF_LOG_PATH