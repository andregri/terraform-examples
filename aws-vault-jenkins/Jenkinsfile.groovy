import hudson.util.Secret
import com.cloudbees.plugins.credentials.CredentialsScope
import com.datapipe.jenkins.vault.credentials.VaultTokenCredential

def vault_cred_id = 'vault-jenkins-auth'
def vault_addr = 'http://44.197.182.74:8200'

pipeline {
    agent any

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
                        // Get role id
                        role_id_response = httpRequest(
                            quiet: true,
                            url: env.VAULT_ADDR + '/v1/auth/pipeline/role/pipeline-role/role-id',
                            httpMode: 'GET',
                            customHeaders: [
                                [name:'X-Vault-Token', value: env.VAULT_TOKEN],
                                [name:'X-Vault-Request', value:'true']
                            ],
                            consoleLogResponseBody: false
                        )
                        def ROLE_ID = readJSON(text: role_id_response.content).data.role_id

                        // Get wrapped secret id
                        wrapped_secret_response = httpRequest(
                            quiet: true,
                            url: env.VAULT_ADDR + '/v1/auth/pipeline/role/pipeline-role/secret-id',
                            httpMode: 'POST',
                            customHeaders: [
                                [name:'X-Vault-Token', value: env.VAULT_TOKEN],
                                [name:'X-Vault-Wrap-Ttl', value:'300s']
                            ],
                            consoleLogResponseBody: false
                        )
                        def WRAPPED_SECRET_ID = readJSON(text: wrapped_secret_response.content).wrap_info.token

                        // Unwrap the secret id
                        String unwrap_request_body = writeJSON returnText: true, json: ['token': WRAPPED_SECRET_ID]

                        unwrap_secret_response = httpRequest(
                            quiet: true,
                            url: env.VAULT_ADDR + '/v1/sys/wrapping/unwrap',
                            httpMode: 'PUT',
                            customHeaders: [
                                [name:'X-Vault-Token', value: env.VAULT_TOKEN],
                                [name:'X-Vault-Request', value:'true']
                            ],
                            consoleLogResponseBody: false,
                            requestBody: unwrap_request_body
                        )

                        // If unwrapping request fails, send notification...
                        if (unwrap_secret_response.status != 200) {
                            currentBuild.result = 'FAILURE'
                            notifyFailed()
                            error('Error unwrapping the secret id.')
                        }

                        def SECRET_ID = readJSON(text: unwrap_secret_response.content).data.secret_id

                        // Use role-id and secret-id to get a token
                        pipeline_token_response = httpRequest(
                            quiet: true,
                            url: env.VAULT_ADDR + '/v1/auth/pipeline/login',
                            httpMode: 'PUT',
                            customHeaders: [
                                [name:'X-Vault-Token', value: env.VAULT_TOKEN],
                                [name:'X-Vault-Request', value:'true']
                            ],
                            requestBody: writeJSON(returnText: true, json: [
                                'role_id': ROLE_ID, 'secret_id': SECRET_ID
                            ]),
                            consoleLogResponseBody: false
                        )
                        env.PIPELINE_VAULT_TOKEN = readJSON(text: pipeline_token_response.content).auth.client_token
                    }
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    VaultTokenCredential pipelineCredential = new VaultTokenCredential(
                        CredentialsScope.GLOBAL,
                        'custom-credential',
                        'My Custom Credential',
                        Secret.fromString("${env.PIPELINE_VAULT_TOKEN}")
                    )
                    def configuration = [vaultUrl: vault_addr, engineVersion: 1,
                            vaultCredential: pipelineCredential]
                    def secrets = [
                        [path: 'db-creds/db', engineVersion: 1, secretValues: [
                            [envVar: 'testing', vaultKey: 'user'],
                            [envVar: 'testing_again', vaultKey: 'password']]],
                        [path: 'aws/creds/pipeline-role', engineVersion: 1, secretValues: [
                            [envVar: 'testing1', vaultKey: 'access_key'],
                            [envVar: 'testing_again1', vaultKey: 'secret_key']]]
                    ]
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh '''
                        echo $testing1 > /tmp/creds
                        echo $testing_again1 >> /tmp/creds
                        cat /tmp/creds
                        '''
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
                            curl --silent -H "X-Vault-Request: true" -H "X-Vault-Token: ${env.PIPELINE_VAULT_TOKEN}" ${vault_addr}/v1/db-creds/db
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

                    /*git branch: 'main', url: 'https://github.com/andregri/terraform-examples.git'
                    
                    sh("""
                        cd "${WORKSPACE}/aws-vault-jenkins/app"
                        terraform init -no-color
                        terraform apply -auto-approve -no-color
                        terraform destroy -auto-approve -no-color
                    """)*/
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

def notifyFailed() {
    emailext (
        subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
        body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
            <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
        recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}