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
    
    # Get role-id and secret-id for jenkins-role
    $ vault read auth/jenkins/role/jenkins-role/role-id
    $ vault write -f auth/jenkins/role/jenkins-role/secret-id
    ```

3. On the **jenkins** instance, run the following commands:

    ```shell
    # Get Jenkins admin password
    $ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```

    Copy and paste the password on the web ui at `http://<public-ip-jenkins-node>:8080` and complete the initial configuration of Jenkins.

    Install **vault** plugin and restart Jenkins.

    Configure Vault plugin adding the Vault URL `http://<public-ip-vault-server>:8200` and the AppRole credentials. Copy paste the role-id and the secret-id from the vault server node.

4. The Vault agent on the app node:

    ```shell
    # Run the vault agent that writes the token to the file 'vault-token-via-agent'
    $ vault agent -config=/home/ubuntu/vault-agent.hcl -log-level=debug

    # Read the secret thanks to the vault token and the webapp-policy permission
    $ curl --silent -H "X-Vault-Request: true" -H "X-Vault-Token: $(cat vault-token-via-agent)" ${VAULT_ADDR}/v1/db-creds/db | jq ".data"
    ```