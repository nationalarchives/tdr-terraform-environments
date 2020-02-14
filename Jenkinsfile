pipeline {
    agent {
        label "master"
    }
    parameters {
        choice(name: "STAGE", choices: ["intg", "staging", "prod"], description: "The stage you are deploying Terraform changes to")
    }
    stages {
        stage('Run Terraform build') {
            agent {
                ecs {
                    inheritFrom 'terraform'
                    taskrole "arn:aws:iam::${env.MANAGEMENT_ACCOUNT}:role/TDRTerraformAssumeRole${params.STAGE.capitalize()}"
                }
            }
            environment {
                TF_VAR_tdr_account_number = getAccountNumberFromStage()
                //no-color option set for Terraform commands as Jenkins console unable to output the colour
                //making output difficult to read
                TF_CLI_ARGS="-no-color"
            }
            stages {
                stage('Set up Terraform workspace') {
                    steps {
                        echo 'Initializing Terraform...'
                        sh 'terraform init'
                        //If Terraform workspace exists continue
                        sh "terraform workspace new ${params.STAGE} || true"
                        sh "terraform workspace select ${params.STAGE}"
                        sh 'terraform workspace list'
                    }
                }
                stage('Run Terraform plan') {
                    steps {
                        echo 'Running Terraform plan...'
                        sh 'terraform plan'
                        slackSend(
                                color: 'good',
                                message: "Terraform plan complete for ${params.STAGE} TDR environment. View here for plan: https://jenkins.tdr-management.nationalarchives.gov.uk/job/${JOB_NAME}/${BUILD_NUMBER}/console",
                                channel: '#tdr'
                        )
                    }
                }
                stage('Approve Terraform plan') {
                    steps {
                        echo 'Sending request for approval of Terraform plan...'
                        slackSend(
                                color: 'good',
                                message: "Do you approve Terraform deployment for ${params.STAGE} TDR environment? https://jenkins.tdr-management.nationalarchives.gov.uk/job/${JOB_NAME}/${BUILD_NUMBER}/input/",
                                channel: '#tdr')
                        input "Do you approve deployment to ${params.STAGE}?"
                    }
                }
                stage('Apply Terraform changes') {
                    steps {
                        echo 'Applying Terraform changes...'
                        sh 'echo "yes" | terraform apply'
                        echo 'Changes applied'
                        slackSend(
                                color: 'good',
                                message: "Deployment complete for ${params.STAGE} TDR environment",
                                channel: '#tdr'
                        )
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Deleting Jenkins workspace...'
            deleteDir()
        }
    }
}

def getAccountNumberFromStage() {
    def stageToAccountMap = [
            "intg": env.INTG_ACCOUNT,
            "staging": env.STAGING_ACCOUNT,
            "prod": env.PROD_ACCOUNT
    ]

    return stageToAccountMap.get(params.STAGE)
}