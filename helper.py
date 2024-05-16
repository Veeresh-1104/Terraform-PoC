import csv
import boto3

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('vgangann-products-table-wr6e8kdjc')

# Read CSV file and insert data into DynamoDB
with open('product_records.csv', 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        table.put_item(Item=row)