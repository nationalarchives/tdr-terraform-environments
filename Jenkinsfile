library("tdr-jenkinslib")

terraformDeployJob(
  stage: params.STAGE,
  repo: "tdr-terraform-environments",
  taskRoleName: "TDRTerraformAssumeRole${params.STAGE.capitalize()}",
  deployment: "Environment",
  terraformDirectoryPath: ".",
  testDelaySeconds: 300,
  terraformNode: "terraform-v13"
)
