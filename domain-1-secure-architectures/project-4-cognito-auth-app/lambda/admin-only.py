"""
SAA Study Project 1.4 - Lambda: Admin Only
Demonstrates group-based authorisation using Cognito JWT group claims.

Key learning: The JWT Authorizer only checks the token is valid and not expired.
FINE-GRAINED authorisation (e.g. "is this user an admin?") is the application's
responsibility — done here inside the Lambda function itself.

Two-layer authorisation model:
  Layer 1 — API Gateway JWT Authorizer: Is the token valid? (rejects 401 if not)
  Layer 2 — Lambda function:            Is the user allowed? (returns 403 if not)
"""

import json


def handler(event, context):
    authorizer = event.get("requestContext", {}).get("authorizer", {})
    claims = authorizer.get("jwt", {}).get("claims", {})

    user_id = claims.get("sub", "unknown")
    email   = claims.get("email", "unknown")

    # Parse Cognito groups from the JWT claim
    # Cognito encodes groups as a comma-separated string in the ID token
    groups_raw = claims.get("cognito:groups", "")
    groups = [g.strip() for g in groups_raw.split(",")] if groups_raw else []

    print(f"[AdminOnly] user_id={user_id} email={email} groups={groups}")

    # ── Group-based authorisation check ──────────────────────────────────────
    if "Admins" not in groups:
        print(f"[AdminOnly] DENIED — {email} is not in Admins group")
        return {
            "statusCode": 403,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error":   "Forbidden",
                "message": "You must be a member of the Admins group to access this endpoint.",
                "yourGroups": groups,
                "hint": (
                    "Add yourself to the Admins group in Cognito, then sign in again "
                    "to get a new token with the updated group claim."
                )
            })
        }

    # ── Admin-only response ───────────────────────────────────────────────────
    print(f"[AdminOnly] GRANTED — {email} is an Admin")
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message":    "Welcome to the Admin panel!",
            "adminUser":  email,
            "userId":     user_id,
            "groups":     groups,
            "adminData": {
                "totalUsers":  42,
                "activeOrders": 7,
                "note": "This data is only visible to Admins"
            }
        })
    }
