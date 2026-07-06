# NOT CURRENTLY USED

# import sys
# from pathlib import Path

# FILE = Path("root_s3_bucket_access.tf")

# REVOKED = 'admin_sso_access_enabled = false'
# GRANTED = 'admin_sso_access_enabled = true'

# target = sys.argv[1]
# action = sys.argv[2]

# content = FILE.read_text()

# if target in ("internal", "both"):
#     if action == "grant":
#         content = content.replace(INTERNAL_S3_BUCKET_ACCESS_REVOKED, INTERNAL_S3_BUCKET_ACCESS_GRANTED)
#     else:
#         content = content.replace(INTERNAL_S3_BUCKET_ACCESS_GRANTED, INTERNAL_S3_BUCKET_ACCESS_REVOKED)

# if target in ("export", "both"):
#     if action == "grant":
#         content = content.replace(EXPORT_S3_BUCKET_ACCESS_REVOKED, EXPORT_S3_BUCKET_ACCESS_GRANTED)
#     else:
#         content = content.replace(EXPORT_S3_BUCKET_ACCESS_GRANTED, EXPORT_S3_BUCKET_ACCESS_REVOKED)

# FILE.write_text(content)

# make this more robust by not searching exactly for the string. a variable that reacts to the changed locals. or regex.
# specific locals for this script. 
# revisit AWS CLI as a solution. 
# testing: merge all and run against staging. or on prod and not terraform. remove apply. 
# think about a timed revoke action. Cron job! Nightly?
# check for double runs. catch errors.