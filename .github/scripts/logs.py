import boto3
import time
import sys
from urllib.parse import quote_plus

client = boto3.client("logs")
timestamp = int(time.time()) * 1000
log_group_name = 'terraform-plan-outputs'
log_stream_name = 'tdr-terraform-backend/pull/162'

log_stream_response = client.describe_log_streams(logGroupName=log_group_name,
                                                  logStreamNamePrefix=log_stream_name,
                                                  descending=True)
with open(sys.argv[1]) as file:
    log_event = [{'timestamp': timestamp, 'message': file.read()}]


def put_log_events(sequence_token=None):
    if sequence_token is None:
        return client.put_log_events(logGroupName=log_group_name,
                                     logStreamName=log_stream_name,
                                     logEvents=log_event)
    else:
        return client.put_log_events(logGroupName=log_group_name,
                                     logStreamName=log_stream_name,
                                     logEvents=log_event,
                                     sequenceToken=sequence_token)


if len(log_stream_response['logStreams']) == 0:
    client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
    response = put_log_events()
elif 'logStreams' in log_stream_response and 'uploadSequenceToken' not in log_stream_response["logStreams"][0]:
    response = put_log_events()
else:
    token = log_stream_response['logStreams'][0]['uploadSequenceToken']
    response = put_log_events(token)

base_url = "https://eu-west-2.console.aws.amazon.com/cloudwatch/home"
encoded_stream_name = quote_plus(quote_plus(log_stream_name))
fragment = f"logsV2:log-groups/log-group/terraform-plan-outputs/log-events/{encoded_stream_name}"
url = f"{base_url}?region=eu-west-2#{fragment}"

print("Terraform plan created")
print(url)
