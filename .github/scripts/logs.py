import boto3
import time
import sys
from urllib.parse import quote_plus

client = boto3.client("logs")
timestamp = int(time.time()) * 1000
log_group_name = f"terraform-plan-outputs-{sys.argv[3]}"
log_stream_name = sys.argv[2]

with open(sys.argv[1]) as file:
    message = file.read()
    if len(message.encode("utf-8")) > 262144:
        message_list = message.split("\n")
        mid_point = len(message_list) // 2
        first_half = "\n".join(message_list[0: mid_point])
        second_half = "\n".join(message_list[mid_point:])
        log_event = [{'timestamp': timestamp, 'message': first_half}, {'timestamp': timestamp, 'message': second_half}]
    else:
        log_event = [{'timestamp': timestamp, 'message': message}]

client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
response = client.put_log_events(logGroupName=log_group_name,
                                 logStreamName=log_stream_name,
                                 logEvents=log_event)

base_url = "https://eu-west-2.console.aws.amazon.com/cloudwatch/home"
encoded_stream_name = quote_plus(quote_plus(log_stream_name))
fragment = f"logsV2:log-groups/log-group/{log_group_name}/log-events/{encoded_stream_name}"
url = f"{base_url}?region=eu-west-2#{fragment}"

print(f"::set-output name=log-url::{url}")
