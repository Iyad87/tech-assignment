#!/bin/bash

# Set the AWS region and profile
export AWS_DEFAULT_REGION=eu-central-1
export AWS_PROFILE=my-aws-profile

# Create an S3 bucket
BUCKET_NAME=my-s3-bucket
aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION

# Enable bucket versioning
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Create a DynamoDB table
TABLE_NAME=my-dynamodb-table
aws dynamodb create-table --table-name $TABLE_NAME --attribute-definitions AttributeName=id,AttributeType=S --key-schema AttributeName=id,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES

# Enable Locked ID on the DynamoDB table
aws dynamodb update-table --table-name $TABLE_NAME --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=alias/aws/dynamodb
