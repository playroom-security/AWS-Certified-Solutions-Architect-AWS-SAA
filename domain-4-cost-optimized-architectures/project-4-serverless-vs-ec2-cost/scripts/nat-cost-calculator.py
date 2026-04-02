"""
SAA Study Project 4.4 - NAT Gateway Cost Calculator
Demonstrates the hidden cost of NAT Gateway for Lambda-in-VPC → S3 traffic,
and the savings achieved by using a VPC Gateway Endpoint instead.
"""

def calculate_nat_gateway_cost(
    hours_per_month: float = 730,        # 24hr × ~30.4 days
    gb_processed_per_month: float = 100, # data through NAT
    nat_hourly_rate: float = 0.045,      # $/hr per NAT GW
    nat_data_rate: float = 0.045,        # $/GB processed
    num_azs: int = 2,                    # one NAT GW per AZ (recommended)
) -> dict:
    """
    Calculate monthly NAT Gateway cost.
    For high availability, you need one NAT Gateway per AZ.
    """
    hourly_cost = nat_hourly_rate * num_azs * hours_per_month
    data_cost = nat_data_rate * gb_processed_per_month
    total = hourly_cost + data_cost

    return {
        "nat_gateway_count": num_azs,
        "monthly_hourly_cost": round(hourly_cost, 2),
        "monthly_data_cost": round(data_cost, 2),
        "monthly_total": round(total, 2),
        "annual_total": round(total * 12, 2),
    }


def calculate_vpc_endpoint_cost(
    gb_processed_per_month: float = 100,
    endpoint_type: str = "gateway",       # gateway (S3, DynamoDB) = FREE
) -> dict:
    """
    VPC Gateway Endpoints for S3 and DynamoDB are FREE.
    VPC Interface Endpoints (PrivateLink) have an hourly charge.
    """
    if endpoint_type == "gateway":
        return {
            "endpoint_type": "Gateway (S3 / DynamoDB)",
            "monthly_cost": 0.00,
            "annual_cost": 0.00,
            "note": "Gateway endpoints are FREE — no hourly charge, no data processing charge!",
        }
    else:
        # Interface endpoint (PrivateLink) - $0.01/hr per AZ + $0.01/GB
        hourly = 0.01 * 2 * 730
        data = 0.01 * gb_processed_per_month
        total = hourly + data
        return {
            "endpoint_type": "Interface (PrivateLink)",
            "monthly_cost": round(total, 2),
            "annual_cost": round(total * 12, 2),
        }


def print_comparison(gb_per_month: float = 100):
    print("=" * 65)
    print("  NAT Gateway vs VPC Endpoint Cost Analysis")
    print(f"  Assumption: {gb_per_month} GB/month S3 traffic from Lambda in VPC")
    print("=" * 65)

    nat = calculate_nat_gateway_cost(gb_processed_per_month=gb_per_month)
    endpoint = calculate_vpc_endpoint_cost(gb_processed_per_month=gb_per_month)

    print(f"\n📦 NAT Gateway (2 AZs for HA):")
    print(f"   Hourly charge:        ${nat['monthly_hourly_cost']:>8.2f}/month")
    print(f"   Data processing:      ${nat['monthly_data_cost']:>8.2f}/month")
    print(f"   Monthly total:        ${nat['monthly_total']:>8.2f}/month")
    print(f"   Annual total:         ${nat['annual_total']:>8.2f}/year")

    print(f"\n🔗 S3 VPC Gateway Endpoint:")
    print(f"   Monthly cost:         ${endpoint['monthly_cost']:>8.2f}/month")
    print(f"   Annual cost:          ${endpoint['annual_cost']:>8.2f}/year")
    print(f"   Note: {endpoint['note']}")

    savings_monthly = nat["monthly_total"] - endpoint["monthly_cost"]
    savings_annual = nat["annual_total"] - endpoint["annual_cost"]

    print(f"\n💰 Savings with VPC Endpoint:")
    print(f"   Monthly savings:      ${savings_monthly:>8.2f}/month")
    print(f"   Annual savings:       ${savings_annual:>8.2f}/year")
    print(f"\n⚡ Services with FREE Gateway Endpoints: S3, DynamoDB")
    print(f"   Add them to your route tables — it's always worth it!")
    print("=" * 65)


if __name__ == "__main__":
    # Low traffic scenario
    print("\n[Scenario 1: Low traffic — 10 GB/month]")
    print_comparison(gb_per_month=10)

    # Medium traffic
    print("\n[Scenario 2: Medium traffic — 100 GB/month]")
    print_comparison(gb_per_month=100)

    # High traffic
    print("\n[Scenario 3: High traffic — 1 TB/month]")
    print_comparison(gb_per_month=1000)
