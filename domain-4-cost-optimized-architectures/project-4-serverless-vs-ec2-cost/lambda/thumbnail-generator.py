"""
SAA Study Project 4.4 - Lambda Thumbnail Generator
Resizes an image from a URL and uploads the thumbnail to S3.

Environment variables required:
  OUTPUT_BUCKET: S3 bucket name for storing thumbnails
"""

import json
import os
import io
import urllib.request
import boto3
from PIL import Image  # Requires Pillow layer or package

s3 = boto3.client("s3")
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
THUMBNAIL_SIZE = (300, 300)


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        image_url = body.get("image_url")

        if not image_url:
            return {"statusCode": 400, "body": json.dumps({"error": "image_url is required"})}

        # Download the image
        with urllib.request.urlopen(image_url) as response:
            image_data = response.read()

        # Resize using Pillow
        image = Image.open(io.BytesIO(image_data))
        image.thumbnail(THUMBNAIL_SIZE)

        # Save resized image to bytes buffer
        output_buffer = io.BytesIO()
        fmt = image.format or "JPEG"
        image.save(output_buffer, format=fmt)
        output_buffer.seek(0)

        # Upload to S3
        key = f"thumbnails/{context.aws_request_id}.jpg"
        s3.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=key,
            Body=output_buffer,
            ContentType="image/jpeg",
        )

        s3_url = f"https://{OUTPUT_BUCKET}.s3.amazonaws.com/{key}"

        return {
            "statusCode": 200,
            "body": json.dumps({
                "thumbnail_url": s3_url,
                "original_url": image_url,
                "size": THUMBNAIL_SIZE,
                "request_id": context.aws_request_id,
            }),
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
