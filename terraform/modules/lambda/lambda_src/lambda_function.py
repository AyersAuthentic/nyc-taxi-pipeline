import json


def lambda_handler(event, context):
    print("Lambda placeholder executed successfully!")
    print(f"Event received: {event}")
    return {"statusCode": 200, "body": json.dumps("Hello from Lambda!")}
