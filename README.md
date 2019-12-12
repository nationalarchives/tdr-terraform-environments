# TDR Terraform Environments

This respository contains the Terraform code to create the AWS resources needed to support the TDR application.

## Terraform Structure

The prototype is divided into separate Terraform modules that represent the different AWS resources that are needed for the TDR project.

The different modules are used by Terraform workspaces which represent three AWS environments:

* intg
* staging
* prod

## Getting Started

### Terraform Backend

Ensure that the Terraform backend has been created.

See here: https://github.com/nationalarchives/tdr-dev-documentation/tree/master/manual/tdr-create-aws-instructure-setup.md

This project creates an s3 Terraform backend that stores the Terraform state for the different TDR environments.

### Install Terraform locally

See: https://learn.hashicorp.com/terraform/getting-started/install.html

### Install AWS CLI Locally

See: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html

### Install Terraform Plugins on Intellij

HCL Language Support: https://plugins.jetbrains.com/plugin/7808-hashicorp-terraform--hcl-language-support

### Add AWS Credentials and Profiles

1. Update local AWS credentials file (~/.aws/credentials) with a user's credentials for the TDR AWS management account:

   ```
   ... other credentials ...

   [terraform]
   aws_access_key_id = ... terraform user access key ...
   aws_secret_access_key = ... terraform user secret access key ...
   ```
    
    The user will need to be added to the relevant group to have permission to create resources in the AWS environments accounts:
    
    * tdr-terraform-developers: access to the TDR Integration environment
    * tdr-terraform-administrators: access to all TDR environments   
   
2. Update local AWS configuration file (~/.aws/config) with the profiles for running Terraform in the different TDR environments:

   ```
   ... other profiles ....
   
   [profile intgterraform]
   region = eu-west-2
   role_arn = ... terraform role arn for intg environment ...
   source_profile = terraform
   
   [profile stagingterraform]
   region = eu-west-2
   role_arn = ... terraform role arn for staging environment ...
   source_profile = terraform
   
   [profile prodterraform]
   region = eu-west-2
   role_arn = ... terraform role arn for prod environment ...
   source_profile = terraform   
   ```
   
## Running Terraform Project

1. Clone TDR Environments project to local machine: https://github.com/nationalarchives/tdr-terraform-environments

2. In command terminal navigate to the folder where the project has been cloned to

3. Create Terraform workspaces corresponding to the TDR environments:

   ```
   [location of project] $ terraform workspace new intg
   
   [location of project] $ terraform workspace new staging
   
   [location of project] $ terraform workspace new prod
   ```
4. Switch to the Terraform workspace corresponding to the TDR environment to be worked on:

   ```
   [location of project] $ terraform workspace select intg
   ```
   
5. Run the following command to ensure Terraform uses the correct credentials:

   ```
   [location of project] $ export AWS_PROFILE=terraform
   ```
   
   There is an issue with Terraform not using the correct profile when more than one profile in the AWs config file
   
6. Initialize Terraform (if not done so previously):

   ```
   [location of project] $ terraform init   
   ```
   
7. Run Terraform to make changes to the TDR environment AWS resources

   ```
   [location of project] $ terraform apply
   ```
## Further Information

* Terraform website: https://www.terraform.io/
* Terraform basic tutorial: https://learn.hashicorp.com/terraform/getting-started/build
