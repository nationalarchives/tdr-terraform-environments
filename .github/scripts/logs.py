import boto3
import time
import sys
from urllib.parse import quote_plus
import os

client = boto3.client("logs")
timestamp = int(time.time()) * 1000
log_group_name = sys.argv[3]
log_stream_name = sys.argv[2]


def split_message(s, length):
    for i in range(0, len(s), length):
        yield s[i:i + length]


log_event = []
with open(sys.argv[1]) as file:
    message = file.read()
    main_message = message.split("::debug::stdout:")[0]
    if len(main_message.encode("utf-8")) > 262144:
        for chunk in split_message(main_message, 262100):
            log_event.append({'timestamp': timestamp, 'message': chunk})
    else:
        log_event = [{'timestamp': timestamp, 'message': main_message}]

client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
response = client.put_log_events(logGroupName=log_group_name,
                                 logStreamName=log_stream_name,
                                 logEvents=log_event)

base_url = "https://eu-west-2.console.aws.amazon.com/cloudwatch/home"
encoded_stream_name = quote_plus(quote_plus(log_stream_name))
fragment = f"logsV2:log-groups/log-group/{log_group_name}/log-events/{encoded_stream_name}"
url = f"{base_url}?region=eu-west-2#{fragment}"

with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
    print(f"log-url={url}", file=fh)
