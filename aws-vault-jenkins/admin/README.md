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
    ## Enable authentication approle method for jenkins node, jenkins pipeline, and application
    #
    $ vault auth enable -path=jenkins approle
    $ vault auth enable -path=pipeline approle
    $ vault auth enable -path=webapp approle

    #
    # Create roles for Jenkins node, Jenkins pipeline, and application
    #
    # secret_id_num_uses=0 means unlimited uses
    $ vault write auth/jenkins/role/jenkins-role \
        secret_id_ttl=10m \
        token_num_uses=10 \
        token_ttl=20m \
        token_max_ttl=30m \
        secret_id_num_uses=0

    $ vault write auth/pipeline/role/pipeline-role \
        secret_id_ttl=300 \
        token_num_uses=1 \
        token_ttl=1800

    $ vault write auth/pipeline/role/pipeline-role \
        secret_id_ttl=600 \
        token_num_uses=1 \
        token_ttl=1800

    ## Write the policy for jenkins-role that allow Jenkins node to get a secret-id for pipeline-role
    $ vim jenkins-policy.hcl
    $ vault policy write jenkins-policy jenkins-policy.hcl
    $ vault write auth/jenkins/role/jenkins-role token_policies=default,jenkins-policy

    ## Write policy for pipeline-role that allows Jenkins pipeline to get a secret-id for webapp-role, get credentials from aws to build infrastructure with terraform
    $ vim pipeline-policy.hcl
    $ vault policy write pipeline-policy pipeline-policy.hcl
    $ vault write auth/pipeline/role/pipeline-role token_policies=default,pipeline-policy

    ## Write the policy for webapp-role that allows the app to 
    $ vim webapp-policy.hcl
    $ vault policy write webapp-policy webapp-policy.hcl
    $ vault write auth/pipeline/role/webapp-role token_policies=default,jenkins-policy

    # 
    $ vault secrets enable -path=db-creds kv
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