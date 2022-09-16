1. Open AWS EC2 dashboard and create a Key Pair named `vault-kp`. Restrict permissions on the .pem file
```shell
$ chmod 400 vault-kp.pem
```

2. Configure AWS credentials locally
```shell
$ aws configure

AWS Access Key ID :
AWS Secret Access Key : 
Default region name [us-east-1]: 
Default output format [json]:
```

3. Build the Vault server and the Jenkins node with Terraform
```shell
$ cd admin
$ terraform apply
```

4. SSH into the Vault server:
```shell
$ vault operator init -stored-shares=1 -recovery-shares=1 \
            -recovery-threshold=1 -key-shares=1 -key-threshold=1 > key.txt

$ vault status

$ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
```

5. Update the variables in `vault/terraform.tfvars`

6. Configure the Vault server with Terraform:
```shell
cd terraform-examples/aws-vault-jenkins/vault/
terraform init
terraform apply
```

7. SSH into the vault server and generate a role-id and a secret-id for the Vault `jenkins-role`
```shell
$ vault read auth/jenkins/role/jenkins-role/role-id

Key        Value
---        -----
role_id    <role-id>

$ vault write -f auth/jenkins/role/jenkins-role/secret-id

Key                   Value
---                   -----
secret_id             <secret_id>
secret_id_accessor    <secret_id_accessor>
secret_id_ttl         30m
```

8. SSH into the Jenkins node and get the initial admin password
```shell
$ ssh -i vault-kp.pem ubuntu@<jenkins-public-ip>
$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword

<initial admin password>
```

9. Configure Jenkins through a browser at `<jenkins-public-ip>:8080` and install the following plugins:
    - Vault
    - HTTP Request
    - Pipeline Utility Steps

10. Add a Vault AppRole credential in Jenkins
    - role-id: ...
    - secret-id: ...
    - path: `jenkins`
    - ID: `vault-jenkins-auth`

11. On Jenkins add a secret named `pipeline-role-id` with the pipeline-role role-id

12. On Jenkins create a pipeline job named 'job1' and click Apply then Save