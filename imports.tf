locals{
    dynamo_table_products = "vgangann-products-table-wr6e8kdjc0"
}

#INFRA DynamoDB Products table
resource "aws_dynamodb_table" "products_table_007"{
    name = local.dynamo_table_products
    hash_key       = "Product_ID"
  range_key      = "Trending_ID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "Product_ID"
    type = "N" # Numeric attribute type
  }

  attribute {
    name = "Trending_ID"
    type = "N"
  }
}