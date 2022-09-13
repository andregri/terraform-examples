def vault_cred_id = 'vault-jenkins-auth'
def vault_addr = 'http://44.197.182.74:8200'

pipeline {
    agent any

    environment {
        PIPELINE_VAULT_TOKEN = ''
    }

    stages {
        stage('Get a Vault token for the pipeline') {
            steps {
                withCredentials([
                    [
                        $class: 'VaultTokenCredentialBinding',
                        credentialsId: vault_cred_id,
                        vaultAddr: vault_addr
                    ]
                ]){
                    script {
                        ROLE_ID = sh(
                            returnStdout: true,
                            script: '''
                                set +x
                                curl --silent \
                                    -H "X-Vault-Request: true" \
                                    -H "X-Vault-Token: $VAULT_TOKEN" \
                                    $VAULT_ADDR/v1/auth/pipeline/role/pipeline-role/role-id \
                                    | jq ".data.role_id"
                            '''
                        )

                        WRAPPED_SECRET_ID = sh(
                            returnStdout: true,
                            script: '''
                                set +x
                                curl --silent --request POST \
                                    -H "X-Vault-Token: $VAULT_TOKEN" \
                                    -H "X-Vault-Wrap-Ttl: 300s" \
                                    "$VAULT_ADDR/v1/auth/pipeline/role/pipeline-role/secret-id" \
                                    | jq ".wrap_info.token"
                                '''
                        )

                        SECRET_ID = sh(
                            returnStdout: true,
                            script: """
                                set +x
                                curl --silent -X PUT \
                                    -H "X-Vault-Request: true" \
                                    -H "X-Vault-Token: $VAULT_TOKEN" \
                                    -d '{\"token\":${WRAPPED_SECRET_ID}}' \
                                    $VAULT_ADDR/v1/sys/wrapping/unwrap \
                                    | jq ".data.secret_id"
                            """
                        )

                        PIPELINE_VAULT_TOKEN = sh(
                            returnStdout: true,
                            script: """
                                set +x
                                curl --silent -X PUT \
                                    -H "X-Vault-Request: true" \
                                    -H "X-Vault-Token: ${VAULT_TOKEN}" \
                                    -d '{\"role_id\":${ROLE_ID},\"secret_id\":${SECRET_ID}}' \
                                    ${VAULT_ADDR}/v1/auth/pipeline/login | jq ".auth.client_token"
                            """
                        )
                    }
                }
            }
        }

        stage('Build app infrastructure with Terraform') {
            environment {
                TF_VAR_aws_region = 'us-east-1'
                TF_VAR_key_name = 'vault-kp'
                TF_VAR_tpl_vault_server_addr = "${vault_addr}"
            }
            steps {
                script {
                    // Read credentials to initialize db
                    def credentials_db = ""
                    credentials_db = sh(
                        returnStdout: true,
                        script: """
                            set +x
                            curl --silent -H "X-Vault-Request: true" -H "X-Vault-Token: ${PIPELINE_VAULT_TOKEN}" ${vault_addr}/v1/db-creds/db
                        """
                    )

                    env.TF_VAR_username = sh(
                        returnStdout: true,
                        script: """
                            set +x
                            echo '${credentials_db}' | jq -r '.data.user'
                        """
                    ).trim()

                    env.TF_VAR_password = sh(
                        returnStdout: true,
                        script: """
                            set +x
                            echo '${credentials_db}' | jq -r '.data.password'
                        """
                    ).trim()

                    // Get temporary AWS credentials
                    credentials_aws = sh(
                        returnStdout: true,
                        script: """
                            set +x
                            curl --silent -H "X-Vault-Request: true" -H "X-Vault-Token: ${PIPELINE_VAULT_TOKEN}" ${vault_addr}/v1/aws/creds/pipeline-role
                        """
                    )

                    env.AWS_ACCESS_KEY_ID = sh(
                        returnStdout: true,
                        script: """
                            set +x
                            echo '${credentials_aws}' | jq -r '.data.access_key'
                        """
                    ).trim()

                    env.AWS_SECRET_ACCESS_KEY = sh(
                        returnStdout: true,
                        script: """
                            set +x 
                            echo '${credentials_aws}' | jq -r '.data.secret_key'
                        """
                    ).trim()

                    git branch: 'main', url: 'https://github.com/andregri/terraform-examples.git'
                    
                    sh("""
                        cd "${WORKSPACE}/aws-vault-jenkins/app"
                        terraform init -no-color
                        terraform apply -auto-approve -no-color
                        terraform destroy -auto-approve -no-color
                    """)
                }
            }
            post {
                failure {
                    sh 'terraform destroy -auto-approve -no-color'
                }
            }
        }
    }
}