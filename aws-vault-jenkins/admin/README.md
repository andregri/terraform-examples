1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

1. On the **server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init -stored-shares=1 -recovery-shares=1 \
            -recovery-threshold=1 -key-shares=1 -key-threshold=1 > key.txt

    # Vault should've been initialized and unsealed
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
    ```