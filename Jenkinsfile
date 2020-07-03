library("tdr-jenkinslib")

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
                TF_VAR_tdr_account_number = tdr.getAccountNumberFromStage(params.STAGE)
                //no-color option set for Terraform commands as Jenkins console unable to output the colour
                //making output difficult to read
                TF_CLI_ARGS="-no-color"
            }
            stages {
                stage('Set up Terraform workspace') {
                    steps {
                        echo 'Initializing Terraform...'
                        sh "git clone https://github.com/nationalarchives/tdr-terraform-modules.git"
                        sshagent(['github-jenkins']) {
                            sh("git clone git@github.com:nationalarchives/tdr-configurations.git")
                        }
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
                        script {
                            tdr.postToDaTdrSlackChannel(colour: "good",
                                                        message: "Terraform plan complete for ${params.STAGE} TDR environment." +
                                                                 "View here for plan: https://jenkins.tdr-management.nationalarchives.gov.uk/job/" +
                                                                 "${JOB_NAME.replaceAll(' ', '%20')}/${BUILD_NUMBER}/console"
                            )
                        }
                    }
                }
                stage('Approve Terraform plan') {
                    steps {
                        echo 'Sending request for approval of Terraform plan...'
                        script {
                            tdr.postToDaTdrSlackChannel(colour: "good",
                                                        message: "Do you approve Terraform deployment for ${params.STAGE} TDR environment?" +
                                                                 "https://jenkins.tdr-management.nationalarchives.gov.uk/job/" +
                                                                 "${JOB_NAME.replaceAll(' ', '%20')}/${BUILD_NUMBER}/input/"
                            )
                        }
                        input "Do you approve deployment to ${params.STAGE}?"
                    }
                }
                stage('Apply Terraform changes') {
                    steps {
                        echo 'Applying Terraform changes...'
                        sh 'echo "yes" | terraform apply'
                        echo 'Changes applied'
                        script {
                            tdr.postToDaTdrSlackChannel(colour: "good",
                                                        message: "Deployment complete for ${params.STAGE} TDR environment"
                            )
                        }

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
        success {
            script {
                if (params.STAGE == "intg"){
                    tdr.runEndToEndTests(300, params.STAGE, BUILD_URL)
                }
            }
        }
    }
}
