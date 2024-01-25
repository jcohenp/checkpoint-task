# microservice1.py

from flask import Flask, request, jsonify
import boto3
from datetime import datetime
import logging

# Set up logging
logging.basicConfig(filename='app.log', level=logging.DEBUG)
logger = logging.getLogger(__name__)


app = Flask(__name__)
sqs = boto3.client('sqs', region_name='us-east-1')
ssm = boto3.client('ssm', region_name='us-east-1')

# Function to get the token from SSM
def get_token_from_ssm():
    try:
        response = ssm.get_parameter(
            Name='token-ms-1',
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(f"Error getting token from SSM: {str(e)}")
        return None

def get_sqs_from_ssm():
    try:
        response = ssm.get_parameter(
            Name='my_sqs',
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(f"Error getting SQS queue from SSM: {str(e)}")
        return None

# Function to validate token correctness
def validate_token(token):
    expected_token = get_token_from_ssm()
    logger.debug(f"Expected token: {expected_token}")
    return token == expected_token

# Function to validate date format and fields
def validate_date_format_and_fields(data):
    try:
        email_data = data.get('data', {})
        email_subject = email_data.get('email_subject')
        email_sender = email_data.get('email_sender')
        email_timestream = email_data.get('email_timestream')
        email_content = email_data.get('email_content')

        # Check if all four fields exist
        if not all([email_subject, email_sender, email_timestream, email_content]):
            return False

        date_time = datetime.fromtimestamp(int(email_timestream))
        if date_time > datetime.now():
            return False

        return True
    except (ValueError, KeyError):
        return False

@app.route('/process_request', methods=['POST'])
def process_request():
    try:
        data = request.json
        token = data.get('token', '')

        # Validate token correctness
        if not validate_token(token):
            logger.error('Invalid token')
            return jsonify({'error': 'Invalid token'}), 400

        # Validate date format and fields
        if not validate_date_format_and_fields(data):
            logger.error('Invalid date format or fields')
            return jsonify({'error': 'Invalid date format or fields'}), 400

        # get sqs queue url
        sqs_url = get_sqs_from_ssm()
        
        # Publish data to SQS
        sqs.send_message(
            QueueUrl=sqs_url,
            MessageBody=str(data.get('data', ''))
        )

        logger.info('Request processed successfully')
        return jsonify({'message': 'Request processed successfully'}), 200

    except Exception as e:
        logger.exception(f"An error occurred: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
