from app.messages_broker.messages_broker import get_bucket_from_ssm

import requests
import pytest
import boto3
import json

ssm = boto3.client('ssm', region_name='us-east-1')

def get_processing_requests_externalIP_from_ssm():
    try:
        response = ssm.get_parameter(
            Name='processing_requests_externalIP',
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Error getting externalIP of processing_requests ms from SSM: {str(e)}")
        return None

BASE_URL = get_processing_requests_externalIP_from_ssm()
S3_BUCKET = get_bucket_from_ssm()

@pytest.fixture
def valid_payload():
    return {
        "data": {
            "email_subject": "Happy new year!",
            "email_sender": "John doe",
            "email_timestream": "1693561101",
            "email_content": "Just want to say... Happy new year!!!",
        },
        "token": "foobar",
    }

def test_valid_request(valid_payload):
    response = requests.post(f"http://{BASE_URL}:5001/process_request", json=valid_payload)
    assert response.status_code == 200

def test_invalid_token():
    invalid_payload = {"data": {}, "token": "invalid_token"}
    response = requests.post(f"http://{BASE_URL}:5001/process_request", json=invalid_payload)
    assert response.status_code == 400

def test_invalid_date_format(valid_payload):
    invalid_payload = valid_payload.copy()
    invalid_payload["data"]["email_timestream"] = "invalid_date"
    response = requests.post(f"http://{BASE_URL}:5001/process_request", json=invalid_payload)
    assert response.status_code == 400

def test_s3_file_content(valid_payload):
    # Make a valid request to trigger S3 file creation
    response = requests.post(f"http://{BASE_URL}:5001/process_request", json=valid_payload)
    assert response.status_code == 200

    # Extract the file key from the response
    file_key = f'sqs_message_{valid_payload["data"]["email_timestream"]}.json'

    # Check if the file exists in S3
    s3 = boto3.client('s3', region_name='us-east-1')

    try:
        # Get the content of the file from S3
        response = s3.get_object(Bucket=S3_BUCKET, Key=file_key)
        file_content = json.loads(response['Body'].read().decode('utf-8'))

        # Assertions on the file content
        assert file_content == valid_payload["data"]

    except s3.exceptions.NoSuchKey:
        # Handle if the file does not exist
        assert False, f"The file {file_key} does not exist in the S3 bucket."

    except Exception as e:
        # Handle other exceptions
        assert False, f"An error occurred: {str(e)}"