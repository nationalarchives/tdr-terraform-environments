import sys
from pathlib import Path

FILE = Path("root_s3_bucket_access.tf")

INTERNAL_REVOKED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'
INTERNAL_GRANTED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'


EXPORT_REVOKED = 'local.environment == "prod" ? [] : [data.aws_ssm_parameter.aws_sso_admin_role.value, data.aws_ssm_parameter.aws_sso_export_role.value]'
EXPORT_GRANTED = 'local.environment == "prod" ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : [data.aws_ssm_parameter.aws_sso_admin_role.value, data.aws_ssm_parameter.aws_sso_export_role.value]'

action = sys.argv[1]
target = sys.argv[1]
reason = sys.argv[1]

content = FILE.read_text()

if target in ("internal", "both"):
    if action == "grant":
        content = content.replace(INTERNAL_REVOKED, INTERNAL_GRANTED)
    else:
        content = content.replace(INTERNAL_GRANTED, INTERNAL_REVOKED)

if target in ("export", "both"):
    if action == "grant":
        content = content.replace(EXPORT_REVOKED, EXPORT_GRANTED)
    else:
        content = content.replace(EXPORT_GRANTED, EXPORT_REVOKED)

FILE.write_text(content)