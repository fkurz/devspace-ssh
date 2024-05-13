# devspace-ssh
PoC for remote SSH development on dev containers deployed in Kubernetes using DevSpace

## Set up

### 1. Install Tooling 

* Terraform
* AWS CLI 
* [DevSpace](https://devspace.sh/) 
* jq 

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

> :information_source: `<the-access-key-id>` and `<the-secret-access-key>` have to be a valid credential pair authorized to create an AWS EKS cluster.

With the infrastructure in place, point `kubectl` to the created EKS cluster.
```bash
THE_REGION="$(terraform -chdir=terraform output -raw region)"
THE_CLUSTER_NAME="$(terraform -chdir=terraform output -raw cluster_name)"
aws eks --region "$THE_REGION" update-kubeconfig --name "$THE_CLUSTER_NAME"
```

### 3. Make dev container image availabler inside the cluster

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

Now, running `devspace dev` while specifying the container image just pushed to our ECR instance should result in an output similar to the following: 
```bash
$ devspace dev --var THE_DEV_CONTAINER_IMAGE="${THE_ECR_REPOSITORY_URL}:latest"
info Using namespace 'devspace'
info Using kube context 'arn:aws:eks:eu-central-1:174394581677:cluster/devspace-eks-QbUEJaxD'
deploy:the-dev-container Deploying chart /home/lima.linux/.devspace/component-chart/component-chart-0.9.1.tgz (the-dev-container) with helm...
deploy:the-dev-container Deployed helm chart (Release revision: 1)
deploy:the-dev-container Successfully deployed the-dev-container with helm
dev:the-dev-container Waiting for pod to become ready...
dev:the-dev-container Selected pod the-dev-container-devspace-847f75dd44-s8m4l
dev:the-dev-container sync  Sync started on: ./ <-> /home/dev
dev:the-dev-container sync  Waiting for initial sync to complete
dev:the-dev-container sync  Initial sync completed
dev:the-dev-container ssh   Port forwarding started on: 60550 -> 8022
dev:the-dev-container ssh   Use 'ssh the-dev-container.devspace.devspace' to connect via SSH
```

We may now connect to the running dev container via SSH on localhost port 60550; or, simply using the SSH configuration with
```bash
ssh the-dev-container.devspace.devspace
```
E.g. we may verify that we are actually running a command on the DevSpace pod, by running
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
