"""
SAA Study Project 1.4 - Lambda: Get Profile
Returns the authenticated user's profile extracted from their Cognito JWT claims.
Triggered by API Gateway HTTP API with Cognito JWT Authorizer.

Key learning: The authorizer validates the token BEFORE Lambda is invoked.
By the time this function runs, you can trust the claims are genuine.
"""


def handler(event, context):
    """
    API Gateway HTTP API passes JWT claims under:
    event['requestContext']['authorizer']['jwt']['claims']
    """
    # Extract claims injected by the Cognito JWT Authorizer
    authorizer = event.get("requestContext", {}).get("authorizer", {})
    claims = authorizer.get("jwt", {}).get("claims", {})

    # Cognito standard claims
    user_id    = claims.get("sub", "unknown")          # Unique user identifier (never changes)
    email      = claims.get("email", "unknown")
    email_verified = claims.get("email_verified", "false")

    # Cognito group membership — used for role-based access control
    # Comes as a comma-separated string: "Admins,Users"
    groups_raw = claims.get("cognito:groups", "")
    groups = [g.strip() for g in groups_raw.split(",")] if groups_raw else []

    # Token metadata
    issued_at  = claims.get("iat", 0)    # Unix timestamp when token was issued
    expires_at = claims.get("exp", 0)    # Unix timestamp when token expires
    token_use  = claims.get("token_use", "unknown")  # "id" or "access"

    print(f"[GetProfile] user_id={user_id} email={email} groups={groups}")

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": __import__("json").dumps({
            "profile": {
                "userId":        user_id,
                "email":         email,
                "emailVerified": email_verified == "true",
                "groups":        groups,
                "isAdmin":       "Admins" in groups,
            },
            "tokenMeta": {
                "issuedAt":  issued_at,
                "expiresAt": expires_at,
                "tokenUse":  token_use,
            },
            "message": "Profile retrieved successfully — token validated by Cognito JWT Authorizer"
        })
    }
