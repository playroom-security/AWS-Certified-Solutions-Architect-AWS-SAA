"""
SAA Study Project 1.3 - Retrieve Secrets from AWS Secrets Manager
Run this on an EC2 instance with the appropriate IAM role attached,
or locally with AWS credentials configured.
"""

import boto3
import json
from botocore.exceptions import ClientError


def get_secret(secret_name: str, region_name: str = "us-east-1") -> dict:
    """
    Retrieve a secret value from AWS Secrets Manager.
    Returns a dict if the secret is JSON, otherwise a plain string.
    """
    client = boto3.client("secretsmanager", region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "DecryptionFailureException":
            print("ERROR: KMS key cannot decrypt the secret. Check key policy.")
        elif error_code == "AccessDeniedException":
            print("ERROR: IAM role does not have permission to retrieve this secret.")
        elif error_code == "ResourceNotFoundException":
            print(f"ERROR: Secret '{secret_name}' not found.")
        raise e

    # Secrets Manager returns either SecretString or SecretBinary
    secret_value = response.get("SecretString") or response.get("SecretBinary")

    # Try to parse as JSON (most secrets are JSON key-value pairs)
    try:
        return json.loads(secret_value)
    except (json.JSONDecodeError, TypeError):
        return {"value": secret_value}


def connect_to_rds_using_secret():
    """
    Example: Use Secrets Manager to get DB credentials dynamically.
    Never hardcode passwords — always retrieve from Secrets Manager!
    """
    secret = get_secret("/prod/rds/mysql-credentials")

    host = secret["host"]
    port = secret["port"]
    dbname = secret["dbname"]
    username = secret["username"]
    password = secret["password"]

    print(f"Connecting to RDS at {host}:{port} as {username}")
    print("Password retrieved dynamically from Secrets Manager ✅")
    print("(In a real app, use these credentials to open a DB connection)")


def list_all_secrets():
    """List all secrets in the account for review."""
    client = boto3.client("secretsmanager", region_name="us-east-1")
    paginator = client.get_paginator("list_secrets")

    print("\nAll secrets in this account:")
    print("-" * 50)
    for page in paginator.paginate():
        for secret in page["SecretList"]:
            rotation = "✅ Rotation ON" if secret.get("RotationEnabled") else "❌ No rotation"
            print(f"  {secret['Name']} | {rotation} | Last changed: {secret.get('LastChangedDate', 'N/A')}")


if __name__ == "__main__":
    print("=" * 60)
    print("  SAA Study - Secrets Manager Demo")
    print("=" * 60)

    # List all secrets
    list_all_secrets()

    print("\n[DEMO] Retrieving RDS credentials dynamically:")
    connect_to_rds_using_secret()

    print("\n[DEMO] Retrieving API keys:")
    api_keys = get_secret("/prod/app/api-keys")
    print(f"  Stripe key present: {'stripe_key' in api_keys}")
    print(f"  SendGrid key present: {'sendgrid_key' in api_keys}")
    print("\n✅ Secrets retrieved successfully without any hardcoded passwords!")
