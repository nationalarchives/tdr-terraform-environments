import boto3
import time
import sys
from urllib.parse import quote_plus

client = boto3.client("logs")
timestamp = int(time.time()) * 1000
log_group_name = f"terraform-plan-outputs-{sys.argv[3]}"
log_stream_name = sys.argv[2]

log_stream_response = client.describe_log_streams(logGroupName=log_group_name,
                                                  logStreamNamePrefix=log_stream_name,
                                                  descending=True)
with open(sys.argv[1]) as file:
    log_event = [{'timestamp': timestamp, 'message': file.read()}]

client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
response = client.put_log_events(logGroupName=log_group_name,
                                 logStreamName=log_stream_name,
                                 logEvents=log_event)

base_url = "https://eu-west-2.console.aws.amazon.com/cloudwatch/home"
encoded_stream_name = quote_plus(quote_plus(log_stream_name))
fragment = f"logsV2:log-groups/log-group/{log_group_name}/log-events/{encoded_stream_name}"
url = f"{base_url}?region=eu-west-2#{fragment}"

print(f"::set-output name=log-url::{url}")
