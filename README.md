# devspace-ssh
PoC for remote SSH development on dev containers deployed in Kubernetes using DevSpace

## Set up

### 1. Install Tooling 

* Terraform
* AWS CLI 
* [DevSpace](https://devspace.sh/) 
* Helm

### 2. Create an EKS cluster on AWS with Terraform

```bash
cd /home/dev
aws configure set aws_access_key_id <the-access-key-id>
aws configure set aws_secret_access_key <the-secret-access-key>
aws configure set default.region eu-central-1
aws configure set default.output json
export TF_VAR_region="$(aws configure get default.region)"
terraform -chdir=terraform init
terraform -chdir=terraform apply 
```

> :information_source: `<the-access-key-id>` and `<the-secret-access-key>` have to be a valid credential pair authorized to create an AWS EKS cluster, AWS ECR registry and related infrastructure.

With the infrastructure in place, point `kubectl` to the created EKS cluster.
```bash
THE_REGION="$(terraform -chdir=terraform output -raw region)"
THE_CLUSTER_NAME="$(terraform -chdir=terraform output -raw cluster_name)"
aws eks --region "$THE_REGION" update-kubeconfig --name "$THE_CLUSTER_NAME"
```

### 3. Make dev container image available inside the cluster

Log in to the ECR
```bash
THE_ECR_REPOSITORY_URL="$(terraform -chdir=terraform output -raw repository_url)"
aws ecr get-login-password --region "$THE_REGION" | docker login --username AWS --password-stdin "$THE_ECR_REPOSITORY_URL"
```

Build and push the dev container image
```bash
docker buildx build --platform linux/amd64 --tag "${THE_REPOSITORY_URL}:latest" --file docker/devcontainer.Dockerfile --push .
```

### 4. Start a dev container on the ECR cluster with DevSpace

```bash
devspace use context "$(kubectl config current-context)"
kubectl create ns devspace
devspace use namespace devspace
```

Deploy your dev container to the remote cluster with DevSpace:
``bash
devspace dev --var THE_DEV_CONTAINER_IMAGE="${THE_ECR_REPOSITORY_URL}:latest"
```

Verify that we are actually running a command on the DevSpace pod, by running
```bash
$ ssh the-dev-container.devspace.devspace 'hostname'
the-dev-container-devspace-847f75dd44-s8m4l
```

The output should be the name of the pod created by DevSpace.

## Clean up

```bash
devspace purge
terraform -chdir=terraform destroy
```
