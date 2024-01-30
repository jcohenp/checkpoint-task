import unittest
from unittest.mock import MagicMock, patch
from app.messages_broker.messages_broker import process_messages


class TestProcessMessages(unittest.TestCase):

    @patch('app.messages_broker.messages_broker.sqs.receive_message')
    @patch('app.messages_broker.messages_broker.sqs.delete_message')
    @patch('app.messages_broker.messages_broker.s3.put_object')
    @patch('app.messages_broker.messages_broker.get_sqs_from_ssm', return_value='fake_queue_url')
    @patch('app.messages_broker.messages_broker.get_bucket_from_ssm', return_value='fake_bucket')
    def test_process_messages(self, mock_get_bucket, mock_get_sqs, mock_put_object, mock_delete_message, mock_receive_message):
        # Prepare a sample SQS message
        sample_message = {
            'Messages': [
                {
                    'Body': '{"email_timestream": 123, "other_data": "value"}',
                    'ReceiptHandle': 'fake_receipt_handle'
                }
            ]
        }

        # Configure the mock receive_message to return the sample message
        mock_receive_message.return_value = sample_message

        # Call the process_messages function
        process_messages(1)

        # Assertions
        mock_get_sqs.assert_called_once()
        mock_get_bucket.assert_called_once()

        # Assert that put_object was called with the correct arguments
        mock_put_object.assert_called_once_with(
            Bucket='fake_bucket',
            Key='sqs_message_123.json',
            Body='{"email_timestream": 123, "other_data": "value"}'
        )

        # Assert that delete_message was called with the correct arguments
        mock_delete_message.assert_called_once_with(
            QueueUrl='fake_queue_url',
            ReceiptHandle='fake_receipt_handle'
        )

if __name__ == '__main__':
    unittest.main()
