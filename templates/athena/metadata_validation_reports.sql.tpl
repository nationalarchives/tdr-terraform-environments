CREATE EXTERNAL TABLE IF NOT EXISTS metadata_validation_reports (
  consignmentId string,
  fileError string,
  `date` string,
  validationErrors ARRAY<STRUCT<
    assetId: string,
    errors: ARRAY<STRUCT<
      validationProcess: string,
      property: string,
      errorKey: string,
      message: string
    >>,
    data: ARRAY<STRUCT<
      name: string,
      value: string
    >>
  >>
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'ignore.malformed.json' = 'TRUE'
)
LOCATION 's3://${bucket_name}/metadata-validation-reports/';

