import unittest
from unittest.mock import MagicMock, patch
from flask import Flask
from app.processing_requests.processing_requests import app


class TestMs2(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()

    @patch('app.processing_requests.processing_requests.get_sqs_from_ssm', return_value='fake_queue_url')
    @patch('app.processing_requests.processing_requests.get_token_from_ssm', return_value='fake_token')
    @patch('app.processing_requests.processing_requests.sqs.send_message')

    def test_process_request(self, mock_send_message, mock_get_token, mock_get_sqs):

        data = {
            "data": {
                "email_content": "Test Content",
                "email_sender": "John Doe",
                "email_subject": "Test Subject",
                "email_timestream": "1693561101",
            },
            "token": "fake_token"
        }

        # Mock the request to the Flask app
        response = self.app.post('/process_request', json=data)

        # Assert that the response status code is 200
        self.assertEqual(response.status_code, 200)

        # Assert that send_message is called with the expected arguments
        mock_send_message.assert_called_once_with(
            QueueUrl='fake_queue_url',
            MessageBody=str(data.get('data', ''))
        )

    @patch('app.processing_requests.processing_requests.get_sqs_from_ssm', return_value='fake_queue_url')
    @patch('app.processing_requests.processing_requests.get_token_from_ssm', return_value='fake_token')
    @patch('app.processing_requests.processing_requests.sqs.send_message')
    def test_invalid_token(self, mock_send_message, mock_get_token, mock_get_sqs):
        # Test with an invalid token
        payload = {
            "data": {
                "email_subject": "Invalid Token Subject",
                "email_sender": "John Doe",
                "email_timestream": "1693561101",
                "email_content": "Invalid Token Content"
            },
            "token": "invalid_token"
        }

        response = self.app.post('/process_request', json=payload)
        assert response.status_code == 400

        # Assert that get_sqs_from_ssm was not called
        mock_get_sqs.assert_not_called()

        # Assert that send_message was not called
        mock_send_message.assert_not_called()

    @patch('app.processing_requests.processing_requests.get_sqs_from_ssm', return_value='fake_queue_url')
    @patch('app.processing_requests.processing_requests.get_token_from_ssm', return_value='fake_token')
    @patch('app.processing_requests.processing_requests.sqs.send_message')
    def test_invalid_date_format(self, mock_send_message, mock_get_token, mock_get_sqs):
        # Test with an invalid date format
        payload = {
            "data": {
                "email_subject": "Invalid Date Subject",
                "email_sender": "John Doe",
                "email_timestream": "invalid_date",
                "email_content": "Invalid Date Content"
            },
            "token": "fake_token"
        }

        response = self.app.post('/process_request', json=payload)
        assert response.status_code == 400

        # Assert that get_sqs_from_ssm was not called
        mock_get_sqs.assert_not_called()

        # Assert that send_message was not called
        mock_send_message.assert_not_called()

if __name__ == '__main__':
    unittest.main()
