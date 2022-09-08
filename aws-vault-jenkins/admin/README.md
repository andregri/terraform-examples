1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

2. On the **vault server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init -stored-shares=1 -recovery-shares=1 \
            -recovery-threshold=1 -key-shares=1 -key-threshold=1 > key.txt

    # Vault should've been initialized and unsealed
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

    #
    ## Enable authentication approle method for jenkins node, jenkins pipeline
    #
    $ vault auth enable -path=jenkins approle
    $ vault auth enable -path=pipeline approle

    #
    # Create roles for Jenkins node, Jenkins pipeline
    #
    # secret_id_num_uses=0 means unlimited uses
    $ vault write auth/jenkins/role/jenkins-role \
        secret_id_ttl=30m \
        token_num_uses=10 \
        token_ttl=20m \
        token_max_ttl=30m \
        secret_id_num_uses=0

    $ vault write auth/pipeline/role/pipeline-role \
        secret_id_ttl=300 \
        token_num_uses=3 \
        token_ttl=1800

    ## Write the policy for jenkins-role that allow Jenkins node to get a secret-id for pipeline-role
    $ vim jenkins-policy.hcl
    $ vault policy write jenkins-policy jenkins-policy.hcl
    $ vault write auth/jenkins/role/jenkins-role token_policies=default,jenkins-policy

    ## Write policy for pipeline-role that allows Jenkins pipeline to get credentials from aws to build infrastructure with terraform, and read kv secrets
    $ vim pipeline-policy.hcl
    $ vault policy write pipeline-policy pipeline-policy.hcl
    $ vault write auth/pipeline/role/pipeline-role token_policies=default,pipeline-policy

    ## Write the policy for webapp-role that allows the app to 
    $ vim webapp-policy.hcl
    $ vault policy write webapp-policy webapp-policy.hcl

    # 
    $ vault secrets enable -path=db-creds kv
    $ vault kv put db-creds/db user=jenkins  password=strongpassword

    # Enable AWS dynamic secrets
    $ vault secrets enable aws
    $ vault write aws/config/root/ access_key="" secret_key="" region="us-east-1"
    $ vault write aws/roles/pipeline-role \
        credential_type=iam_user \
        policy_document=-<<EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "Stmt1426528957000",
                    "Effect": "Allow",
                    "Action": [
                        "ec2:*",
                        "rds:*"
                    ],
                    "Resource": [
                        "*"
                    ]
                }
            ]
        }
EOF
    ```

    ```shell
    # Enable aws authentication method for the vault agent
    $ vault auth enable aws

    # Configure the aws client
    $ vault write -force auth/aws/config/client region="us-east-1" access_key=xxx secret_key=xxx

    # Create a role for the webapp
    # Substitute account_id with yours
    $ vault write auth/aws/role/webapp-role auth_type=iam bound_iam_principal_arn="arn:aws:iam::${account_id}:role/webapp-role" policies=webapp-policy ttl=24h
    ```

3. On the **jenkins** instance, run the following commands:

    ```shell
    # Get Jenkins admin password
    $ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```

    Copy and paste the password on the web ui at `http://<public-ip-jenkins-node>:8080` and complete the initial configuration of Jenkins.

    Install **vault** plugin and restart Jenkins.

    Configure Vault plugin adding the Vault URL `http://<public-ip-vault-server>:8200` and the AppRole credentials. Copy paste the role-id and the secret-id from the vault server node:

    ```shell
    $ vault read auth/jenkins/role/jenkins-role/role-id
    $ vault write -f auth/jenkins/role/jenkins-role/secret-id
    ```

4. The Vault agent on the app node:

    ```shell
    # Run the vault agent that writes the token to the file 'vault-token-via-agent'
    $ vault agent -config=/home/ubuntu/vault-agent.hcl -log-level=debug

    # Read the secret thanks to the vault token and the webapp-policy permission
    $ curl --silent -H "X-Vault-Request: true" -H "X-Vault-Token: $(cat vault-token-via-agent)" ${VAULT_ADDR}/v1/db-creds/db | jq ".data"
    ```