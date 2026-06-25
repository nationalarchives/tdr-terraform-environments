import sys
from pathlib import Path

FILE = Path("root_s3_bucket_access.tf")

REVOKED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'
GRANTED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'

action = sys.argv[1]
content = FILE.read_text()

if action == "grant":
    content = content.replace(REVOKED, GRANTED)
else:
    content = content.replace(GRANTED, REVOKED)

FILE.write_text(content)