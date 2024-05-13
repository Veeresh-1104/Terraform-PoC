def lambda_handler(event, context):
    message = f"Hello {event['name']}"
    return {
        "message": message
    }