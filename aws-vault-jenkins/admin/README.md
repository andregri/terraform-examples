1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

2. On the **server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init -stored-shares=1 -recovery-shares=1 \
            -recovery-threshold=1 -key-shares=1 -key-threshold=1 > key.txt

    # Vault should've been initialized and unsealed
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

    # Create AppRole for Jenkins node and Pipeline with policies
    $ vault auth enable approle

    # Create role for Jenkins
    # secret_id_num_uses=0 means unlimited uses
    $ vault write auth/approle/role/jenkins-role \
        secret_id_ttl=10m \
        token_num_uses=10 \
        token_ttl=20m \
        token_max_ttl=30m \
        secret_id_num_uses=0

    # Fetch the role-id for jenkins-role
    $ vault read auth/approle/role/jenkins-role/role-id

    # Fetch the secret-id for jenkins-role
    $ vault write -f auth/approle/role/jenkins-role/secret-id

    # Write the policy for jenkins-role to a file
    $ vim jenkins-policy.hcl

    # Add the policy to vault
    $ vault policy write jenkins-policy jenkins-policy.hcl

    # Add the policy to jenkins-role
    $ vault write auth/approle/role/jenkins-role token_policies=default,jenkins-policy
    ```