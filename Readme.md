# Instructions for EC2 Recipe


## Configure keys
* Create keys, saving output to local file, preferably "workerkeys".
```
ssh-keygen
```
* Copy public key contents of <keyfile>.pub (the file you just created) `TF_VAR_EC2_PUBLIC_KEY` variable in .env file, and re-source file: `source .env`

## Create .env file
```
#!/bin/bash
export TF_VAR_VPS_NAME="<name of VPS>"
export TF_VAR_REGION="us-east-1"
export TF_VAR_AVAIL_ZONE="us-east-1b"
#openssl rand -hex 10
export TF_VAR_BUCKET_NAME="<globally unique>"
export TF_VAR_BUCKET_KEY="tfstate-key"
export TF_VAR_KEYS_NAME="workerkeys"
export TF_VAR_PROJECT="<your project>"
export TF_VAR_EC2_PUBLIC_KEY="<public key from ssh-keygen utility above>"
```
## S3 Setup for remote state

* Login to AWS CLI
```
rm  -rf ~/.aws/credentials
aws configure
```

* Create S3 bucket for TF State.
```
 aws s3api  create-bucket --bucket $TF_VAR_BUCKET_NAME --region $TF_VAR_REGION
```

## Preconfigure VPC
* Understand if you have a default VPC:
```
aws ec2 describe-vpcs --region <region name you plan on using>
```
* If there is no default VPC:
```
aws ec2 create-default-vpc --region $TF_VAR_REGION 
```

## Init TF Backend

```
terraform init --backend-config "bucket=$TF_VAR_BUCKET_NAME" --backend-config "key=$TF_VAR_BUCKET_KEY" --backend-config "region=$TF_VAR_REGION"
```

## Execing TF
* Plan:
```
terraform plan
```
* Execute, taking note of the IP at the end.
```
terraform -auto-approve
```

## Logging in
* Regular login
```
ssh -i $TF_VAR_KEYS_NAME ec2-user@$(tf output static_ip_addr) 
```
* Create a tunnel for SSH to the internet, then point Firefox SOCKS5 proxy to 127.0.0.1, 8080.
```
ssh -i $TF_VAR_KEYS_NAME -D 8080 ec2-user@$(tf output static_ip_addr)
```
