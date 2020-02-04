pipeline {
    agent {
        label "master"
    }
    environment {
        stage = getStageFromBranch()
    }
    stages {
        stage('Run Terraform build') {
            agent {
                ecs {
                    inheritFrom 'terraform'
                    taskrole "arn:aws:iam::${env.MANAGEMENT_ACCOUNT}:role/TDRTerraformAssumeRole${env.stage.capitalize()}"
                }
            }
            environment {
                TF_VAR_tdr_account_number = getAccountNumberFromBranch()
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
                        sh "terraform workspace new ${env.stage} || true"
                        sh "terraform workspace select ${env.stage}"
                        sh 'terraform workspace list'
                    }
                }
                stage('Run Terraform plan') {
                    steps {
                        echo 'Running Terraform plan...'
                        sh 'terraform plan'
                        slackSend(
                                color: 'good',
                                message: "Terraform plan complete for ${env.stage} TDR environment. View here for plan: https://d1is5dxb7gt8v.cloudfront.net/job/${JOB_NAME}/${BUILD_NUMBER}/console",
                                channel: '#tdr'
                        )
                    }
                }
                stage('Approve Terraform plan') {
                    steps {
                        echo 'Sending request for approval of Terraform plan...'
                        slackSend(
                                color: 'good',
                                message: "Do you approve Terraform deployment for ${env.stage} TDR environment? https://d1is5dxb7gt8v.cloudfront.net/job/${JOB_NAME}/${BUILD_NUMBER}/input/",
                                channel: '#tdr')
                        input "Do you approve deployment to ${env.stage}?"
                    }
                }
                stage('Apply Terraform changes') {
                    steps {
                        echo 'Applying Terraform changes...'
                        sh 'echo "yes" | terraform apply'
                        echo 'Changes applied'
                        slackSend(
                                color: 'good',
                                message: "Deployment complete for ${env.stage} TDR environment",
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

def getStageFromBranch() {

    def branchToStageMap = [
            "origin/master": "intg",
            "origin/staging": "staging",
            "origin/prod": "prod"
    ]

    return branchToStageMap.get(env.GIT_BRANCH)
}

def getAccountNumberFromBranch() {

    def branchToAccountMap = [
            "origin/intg": env.INTG_ACCOUNT,
            "origin/staging": env.STAGING_ACCOUNT,
            "origin/prod": env.PROD_ACCOUNT
    ]

    return branchToAccountMap.get(env.GIT_BRANCH)
}