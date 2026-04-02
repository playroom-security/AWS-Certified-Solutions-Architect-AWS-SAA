"""
SAA Study Project 2.2 - ProcessOrder Lambda Function
Triggered by SQS queue. Validates order, writes to DynamoDB, publishes to SNS.
"""

import json
import os
import uuid
import boto3
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ.get("ORDERS_TABLE", "Orders")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")


def lambda_handler(event, context):
    """
    SQS trigger: processes a batch of up to 10 messages.
    Returns batch item failures for partial failures.
    """
    table = dynamodb.Table(TABLE_NAME)
    batch_item_failures = []

    print(f"Processing {len(event['Records'])} messages from SQS")

    for record in event["Records"]:
        message_id = record["messageId"]
        try:
            # Parse the SQS message body
            body = json.loads(record["body"])
            print(f"Processing order: {body}")

            # Validate required fields
            if "orderId" not in body or "item" not in body:
                raise ValueError(f"Invalid order format: {body}")

            order_id = body.get("orderId", str(uuid.uuid4()))
            timestamp = datetime.utcnow().isoformat()

            # Write to DynamoDB
            table.put_item(Item={
                "orderId": order_id,
                "item": body["item"],
                "quantity": body.get("quantity", 1),
                "status": "PROCESSED",
                "processedAt": timestamp,
                "customerId": body.get("customerId", "anonymous"),
            })

            print(f"✅ Order {order_id} written to DynamoDB")

            # Publish to SNS for fan-out to downstream services
            if SNS_TOPIC_ARN:
                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject="Order Processed",
                    Message=json.dumps({
                        "orderId": order_id,
                        "item": body["item"],
                        "status": "PROCESSED",
                        "timestamp": timestamp,
                    }),
                    MessageAttributes={
                        "eventType": {
                            "DataType": "String",
                            "StringValue": "ORDER_PROCESSED",
                        }
                    }
                )
                print(f"✅ Published ORDER_PROCESSED event to SNS")

        except Exception as e:
            print(f"❌ Failed to process message {message_id}: {str(e)}")
            # Report this message as a failure — SQS will retry it
            # After maxReceiveCount failures, it moves to the DLQ
            batch_item_failures.append({"itemIdentifier": message_id})

    print(f"Done. Failures: {len(batch_item_failures)}/{len(event['Records'])}")

    # Return batch item failures for partial batch response
    return {"batchItemFailures": batch_item_failures}
