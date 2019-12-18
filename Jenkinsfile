pipeline {
    agent {
        ecs {
            inheritFrom 'terraform'
        }
    }
    environment {
        stage = getStageFromBranch()
        account_number = getAccountNumberFromBranch()
    }
    stages {
        stage('Configure AWS credentials') {
            steps {
                echo 'Configuring AWS credentials...'
                sh 'java -version'
                sh "aws configure set role_arn arn:aws:iam::${env.account_number}:role/${env.stage}-terraform-role --profile ${env.stage}terraform"
                sh "aws configure set region eu-west-2 --profile ${env.stage}terraform"
                sh "aws configure set source_profile default --profile ${env.stage}terraform"
                withCredentials([[
                                         $class: 'AmazonWebServicesCredentialsBinding',
                                         credentialsId: "${env.stage}Terraform",
                                         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                                 ]]) {
                    sh 'aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}'
                    sh 'aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}'
                    sh 'cat ~/.aws/config'
                    sh 'cat ~/.aws/credentials'
                }
                sh 'export AWS_PROFILE=default'
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

def getAccountNumberFromBranch() {
    def accountNumber = env.INTG_ACCOUNT

    def branchToAccountMap = [
            "origin/staging": env.STAGING_ACCOUNT,
            "origin/prod": env.PROD_ACCOUNT
    ]

    if (branchToAccountMap.get(env.GIT_BRANCH)) {
        stage = branchToStageMap.get(env.GIT_BRANCH)
    }

    return accountNumber
}
