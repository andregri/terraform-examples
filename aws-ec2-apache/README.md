### 1. Deploy the infrastructure
```
terraform init
terraform apply
```

### 2. Replace a resource
```
terraform apply -replace "aws_instance.example"
```

### 3. Move a resource to a different state file
```
cd new_state
terraform init
terraform state mv -state-out="../terraform.tfstate" aws_instance.example_new aws_instance.example_new
```

Verify that the resource does not exist anymore in new_state with `terraform state list`

Verify that the resource has been moved to `../terraform.tfstate` with `terraform state list`

If you run `terraform plan`, Terraform plans to destroy that resource because it is not in the configuration file. So copy the resource in the configuration file.

`terraform apply` does not make any change because the resource already exists.

Go back to `new_state` to destroy everything but nothing is destroyed because the instance has been moved and the security group is a `data`:
```
cd new_state
terraform destroy
```

### 4. Remove a resource from a state
Remove the security group from the state and verify with `terraform state list`.

Import the security group again with `terraform import`

```
cd ..
terraform state rm aws_security_group.sg_8080
terraform state list
terraform import aws_security_group.sg_8080 $(terraform output -raw security_group)
```

### 5. Refreshing modified infrastructure
Remove an instance from AWS EC2 Console or CLI and then run `terraform refresh` to align your state with the real infrastructure.

```
aws ec2 terminate-instances --instance-ids $(terraform output -raw instance_id)
terraform refresh
terraform state list
```

`terraform refresh` does not update your configuration file but you have to do it manually.