pipeline {
    agent {
        label "master"
    }
    environment {
        mgmtAccount = sh(returnStdout: true, script: 'echo $MANAGEMENT_ACCOUNT').trim()
        stage = getStageFromBranch()
    }
    stages {
        stage('Run Terraform build') {
            agent {
                ecs {
                    inheritFrom 'terraform'
                    taskrole "arn:aws:iam::${env.mgmtAccount}:role/TDRTerraformAssumeRole${env.stage.capitalize()}"
                }
            }
            stages {
                stage('Configure AWS credentials') {
                    steps {
                        echo 'Configuring AWS credentials...'
                        sh 'aws configure list'
                    }
                }
                stage('Set up Terraform workspace') {
                    //no-color option set for Terraform commands as Jenkins console unable to output the colour
                    //making output difficult to read
                    steps {
                        echo 'Initializing Terraform...'
                        sh 'terraform init -no-color'
                        //If Terraform workspace exists continue
                        sh "terraform workspace new ${env.stage} -no-color || true"
                        sh "terraform workspace select ${env.stage} -no-color"
                        sh 'terraform workspace list -no-color'
                    }
                }
                stage('Run Terraform plan') {
                    steps {
                        echo 'Running Terraform plan...'
                        sh 'terraform plan -no-color'
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
                        sh 'echo "yes" | terraform apply -no-color'
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

    def stage = "intg"

    def branchToStageMap = [
            "origin/staging": "staging",
            "origin/prod": "prod"
    ]

    if (branchToStageMap.get(env.GIT_BRANCH)) {
        stage = branchToStageMap.get(env.GIT_BRANCH)
    }

    return stage
}