library("tdr-jenkinslib")

terraformDeployJob(
  stage: params.STAGE,
  repo: "tdr-terraform-environments",
  taskRoleName: "TDRTerraformAssumeRole${params.STAGE.capitalize()}",
  deployment: "Environment",
  modulesBranch: "terraform-v1",
  terraformNode: "terraform-latest",
  terraformDirectoryPath: ".",
  testDelaySeconds: 300
)
