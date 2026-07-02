import sys
from pathlib import Path

FILE = Path("root_s3_bucket_access.tf")

EXPORT_S3_BUCKET_ACCESS_GRANTED = 'local.environment == "prod" ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : [data.aws_ssm_parameter.aws_sso_admin_role.value, data.aws_ssm_parameter.aws_sso_export_role.value]'
EXPORT_S3_BUCKET_ACCESS_REVOKED = 'local.environment == "prod" ? [] : [data.aws_ssm_parameter.aws_sso_admin_role.value, data.aws_ssm_parameter.aws_sso_export_role.value]'

INTERNAL_S3_BUCKET_ACCESS_GRANTED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [data.aws_ssm_parameter.aws_sso_admin_role.value] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'
INTERNAL_S3_BUCKET_ACCESS_REVOKED = 'aws_sso_internal_bucket_access_roles = local.environment == "prod" ? [] : [data.aws_ssm_parameter.aws_sso_admin_role.value]'

target = sys.argv[1]
action = sys.argv[2]
reason = sys.argv[3]
ticket = sys.argv[4]

content = FILE.read_text()

if target in ("internal", "both"):
    if action == "grant":
        content = content.replace(INTERNAL_S3_BUCKET_ACCESS_REVOKED, INTERNAL_S3_BUCKET_ACCESS_GRANTED)
    else:
        content = content.replace(INTERNAL_S3_BUCKET_ACCESS_GRANTED, INTERNAL_S3_BUCKET_ACCESS_REVOKED)

if target in ("export", "both"):
    if action == "grant":
        content = content.replace(EXPORT_S3_BUCKET_ACCESS_REVOKED, EXPORT_S3_BUCKET_ACCESS_GRANTED)
    else:
        content = content.replace(EXPORT_S3_BUCKET_ACCESS_GRANTED, EXPORT_S3_BUCKET_ACCESS_REVOKED)

FILE.write_text(content)
