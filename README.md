<!-- This file was automatically generated by the `build-harness`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->

[![Cloud Posse](https://cloudposse.com/logo-300x69.svg)](https://cloudposse.com)

# prod.cloudposse.co [![Codefresh Build Status](https://g.codefresh.io/api/badges/build?repoOwner=cloudposse&repoName=prod.cloudposse.co&branch=master&pipelineName=prod.cloudposse.co&accountName=cloudposse&type=cf-1)](https://g.codefresh.io/repositories/cloudposse/prod.cloudposse.co/builds?filter=trigger:build;branch:master;service:5b234974667ab79287990636~prod.cloudposse.co) [![Latest Release](https://img.shields.io/github/release/cloudposse/prod.cloudposse.co.svg)](https://github.com/cloudposse/prod.cloudposse.co/releases) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)


Terraform/Kubernetes Reference Infrastructure for Cloud Posse Production Organization in AWS.

__NOTE:__ Before creating the Production infrastructure, you need to provision the [Parent ("Root") Organization](https://github.com/cloudposse/root.cloudposse.co) in AWS (because it creates resources needed for all other accounts).

Follow the steps in [README](https://github.com/cloudposse/root.cloudposse.co) first. You need to do it only once.

## Introduction

We use [geodesic](https://github.com/cloudposse/geodesic) to define and build world-class cloud infrastructures backed by AWS and powered by Kubernetes.

`geodesic` exposes many tools that can be used to define and provision AWS and Kubernetes resources.

Here is the list of tools we use to provision `cloudposse.co` infrastructure:

* [aws-vault](https://github.com/99designs/aws-vault)
* [chamber](https://github.com/segmentio/chamber)
* [terraform](https://www.terraform.io/)
* [kops](https://github.com/kubernetes/kops)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
* [helm](https://helm.sh/)
* [helmfile](https://github.com/roboll/helmfile)


---

This project is part of our comprehensive ["SweetOps"](https://docs.cloudposse.com) approach towards DevOps. 


It's 100% Open Source and licensed under the [APACHE2](LICENSE).










## Quick Start


### Setup AWS Role

__NOTE:__ You need to do it only once.

Configure AWS profile in `~/.aws/config`. Make sure to change username (username@cloudposse.com) to your own.

```bash
[profile cpco-prod-admin]
region=us-west-2
role_arn=arn:aws:iam::590638247571:role/OrganizationAccountAccessRole
mfa_serial=arn:aws:iam::681280261279:mfa/username@cloudposse.com
source_profile=cpco
```

### Install and setup aws-vault

__NOTE:__ You need to do it only once.

We use [aws-vault](https://docs.cloudposse.com/tools/aws-vault/) to store IAM credentials in your operating system's secure keystore and then generates temporary credentials from those to expose to your shell and applications.

Install [aws-vault](https://docs.cloudposse.com/tools/aws-vault/) on your local computer first.

On MacOS, you may use `homebrew cask`

```bash
brew cask install aws-vault
```

Then setup your secret credentials for AWS in `aws-vault`
```bash
aws-vault add --backend file cpco
```

For more info, see [aws-vault](https://docs.cloudposse.com/tools/aws-vault/)


## Examples

### Build Docker Image

```
# Initialize the project's build-harness
make init

# Build docker image
make docker/build
```

### Install the wrapper shell
```bash
make install
```

### Run the shell
```bash
prod.cloudposse.co
```

### Login to AWS with your MFA device
```bash
assume-role
```

### Populate `chamber` secrets

__NOTE:__ You need to do it only once for a given set of secrets. Repeat this step if you want to add new secrets.

Populate `chamber` secrets for `kops` project (make sure to change the keys and values to reflect your environment; add new secrets as needed)

```bash
chamber write kops <key1> <value1>
chamber write kops <key2> <value2>
...
```

__NOTE:__ Run `chamber list -e kops` to list the secrets stored for `kops` project

Populate `chamber` secrets for `backing-services` project (make sure to change the values to reflect your environment; add new secrets as needed)

```bash
chamber write backing-services TF_VAR_POSTGRES_ADMIN_NAME admin
chamber write backing-services TF_VAR_POSTGRES_ADMIN_PASSWORD supersecret
chamber write backing-services TF_VAR_POSTGRES_DB_NAME app
```

__NOTE:__ Run `chamber list -e backing-services` to list the secrets stored for `backing-services` project

__NOTE:__ Before provisioning AWS resources with Terraform, you need to create `tfstate-backend` first (S3 bucket to store Terraform state and DynamoDB table for state locking).

Follow the steps in this [README](conf/tfstate-backend/README.md). You need to do it only once.

After `tfstate-backend` has been provisioned, follow the rest of the instructions in the order shown below.


### Provision `dns` with Terraform

Change directory to `dns` folder
```bash
cd /conf/dns
```

Run Terraform
```bash
init-terraform
terraform plan
terraform apply
```

For more info, see [geodesic-with-terraform](https://docs.cloudposse.com/geodesic/module/with-terraform/)

### Provision `cloudtrail` with Terraform

```bash
cd /conf/cloudtrail
init-terraform
terraform plan
terraform apply
```

### Provision `acm` with Terraform

```bash
cd /conf/acm
init-terraform
terraform plan
terraform apply
```

### Provision `chamber` with Terraform

```bash
cd /conf/chamber
init-terraform
terraform plan
terraform apply
```




## Makefile Targets
```
Available targets:

  help                                This help screen
  help/all                            Display help for all targets

```
### Provision the Kops cluster

We create a `kops` cluster from a manifest.

The manifest template is located in [`/templates/kops/default.yaml`](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml)
and is compiled by running `build-kops-manifest` in the [`Dockerfile`](Dockerfile).

Provisioning a `kops` cluster takes three steps:

1. Provision the `kops` backend (config S3 bucket, cluster DNS zone, and SSH keypair to access the k8s masters and nodes) in Terraform
2. Update the [`Dockerfile`](Dockerfile) and rebuild/restart the `geodesic` shell to generate a `kops` manifest file
3. Execute the `kops` manifest file to create the `kops` cluster


Change directory to `kops` folder
```bash
cd /conf/kops
```

Run Terraform to provision the `kops` backend (S3 bucket, DNS zone, and SSH keypair)
```bash
init-terraform
terraform plan
terraform apply
```

From the Terraform outputs, copy the `zone_name` and `bucket_name` into the ENV vars `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` in the [`Dockerfile`](Dockerfile).

The `Dockerfile` `kops` config should look like this:

```docker
# kops config
ENV KOPS_CLUSTER_NAME="us-west-2.prod.cloudposse.co"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://cpco-prod-kops-state"
ENV KOPS_STATE_STORE_REGION="us-west-2"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="t2.large"
ENV NODE_MACHINE_TYPE="t2.large"
ENV NODE_MAX_SIZE="3"
ENV NODE_MIN_SIZE="3"
```

Type `exit` (or hit ^D) to leave the shell.

Note, if you've assumed a role, you'll first need to leave that also by typing `exit` (or hit ^D).

Rebuild the Docker image
### Provision `vpc` from `backing-services` with Terraform

__NOTE:__ We provision `backing-services` in two phases because:

* `aurora-postgres` and `elasticache-redis` depend on `vpc-peering` (they use `kops` Security Group to allow `kops` applications to connect)
* `vpc-peering` depends on `vpc` and `kops` (it creates a peering connection between the two networks)

To break the circular dependencies, we provision `kops`, then `vpc` (from `backing-services`), then `vpc-peering`,
and finally the rest of `backing-services` (`aurora-postgres` and `elasticache-redis`).

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the specified service (`backing-services`)
and then execute the given commands (`terraform plan` and `terraform apply`)


```bash
cd /conf/backing-services
init-terraform
chamber exec backing-services -- terraform plan -target=module.identity -target=module.vpc -target=module.subnets
chamber exec backing-services -- terraform apply -target=module.identity -target=module.vpc -target=module.subnets
```

### Provision `vpc-peering` from `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
init-terraform
terraform plan -target=module.identity -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
terraform apply -target=module.identity -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
```

### Provision the rest of `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
terraform plan
terraform apply
```

### Provision the rest of `backing-services` with Terraform

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the specified service (`backing-services`)
and then execute the given commands (`terraform plan` and `terraform apply`)

```bash
cd /conf/backing-services
chamber exec backing-services -- terraform plan
chamber exec backing-services -- terraform apply
```
### Provision Kubernetes Resources with Helmfile

We use [helmfile](https://github.com/roboll/helmfile) to deploy [Helm](https://helm.sh/) [charts](https://github.com/kubernetes/charts) to provision Kubernetes resources.

`helmfile.yaml` is located in the `/conf/kops` directory in `geodesic` container (see [helmfile.yaml](https://github.com/cloudposse/geodesic/blob/master/conf/kops/helmfile.yaml)).

Change the current directory to `kops`

```bash
cd /conf/kops
```

Deploy the Helm charts

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the `kops` service and then execute the given command (`helmfile sync`)

``` bash
kops export kubecfg $KOPS_CLUSTER_NAME
chamber exec kops -- helmfile sync
```

```
✅   (cpco-prod-admin) kops ➤  chamber exec kops -- helmfile sync
exec: helm repo add stable https://kubernetes-charts.storage.googleapis.com
"stable" has been added to your repositories
exec: helm repo add cloudposse-incubator https://charts.cloudposse.com/incubator/
"cloudposse-incubator" has been added to your repositories
exec: helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "cloudposse-incubator" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "coreos-stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
exec: helm upgrade --install kube2iam stable/kube2iam --version 0.8.5 --namespace kube-system --set tolerations[0].key=node-role.kubernetes.io/master,tolerations[0].effect=NoSchedule,aws.region=us-west-2,extraArgs.auto-discover-base-arn=true,host.iptables=true,host.interface=cali+,resources.limits.cpu=4m,resources.limits.memory=16Mi,resources.requests.cpu=4m,resources.requests.memory=16Mi
exec: helm upgrade --install kube-lego cloudposse-incubator/kube-lego --version 0.1.2 --namespace kube-system --values /localhost/Documents/Projects/CloudPosse/Programs/Projects/Joany/prod.cloudposse.co/conf/kops/values/kube-lego.yaml
exec: helm upgrade --install ingress cloudposse-incubator/nginx-ingress --version 0.1.7 --namespace kube-system --values /localhost/Documents/Projects/CloudPosse/Programs/Projects/Joany/prod.cloudposse.co/conf/kops/values/ingress.yaml
exec: helm upgrade --install external-dns stable/external-dns --version 0.5.4 --namespace kube-system --set nodeSelector.kubernetes\.io/role=master,extraEnv.EXTERNAL_DNS_SOURCE=service
ingress,tolerations[0].key=node-role.kubernetes.io/master,tolerations[0].effect=NoSchedule,txtOwnerId=us-west-2.prod.cloudposse.co,txtPrefix=184f3df5-53c6-4071-974b-2d8de32e82c7-,publishInternalServices=true,provider=aws,podAnnotations.iam\.amazonaws\.com/role=cpco-prod-external-dns,resources.limits.cpu=100m,resources.limits.memory=128Mi,resources.requests.cpu=100m,resources.requests.memory=128Mi
exec: helm upgrade --install chart-repo cloudposse-incubator/chart-repo --version 0.2.1 --namespace kube-system --values /localhost/Documents/Projects/CloudPosse/Programs/Projects/Joany/prod.cloudposse.co/conf/kops/values/chart-repo.yaml
Release "kube-lego" does not exist. Installing it now.
NAME:   kube-lego
LAST DEPLOYED: Wed Apr 18 14:46:47 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                 DATA  AGE
kube-lego-kube-lego  2     1s

==> v1beta1/Deployment
NAME                 DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
kube-lego-kube-lego  1        1        1           0          1s

==> v1/Pod(related)
NAME                                 READY  STATUS             RESTARTS  AGE
kube-lego-kube-lego-d88d9c968-kr94m  0/1    ContainerCreating  0         1s


NOTES:
Kube Lego has been installed to the kube-system as kube-lego-kube-lego.

Lego endpoint: https://acme-v01.api.letsencrypt.org/directory


Release "kube2iam" does not exist. Installing it now.
NAME:   kube2iam
LAST DEPLOYED: Wed Apr 18 14:46:47 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/DaemonSet
NAME      DESIRED  CURRENT  READY  UP-TO-DATE  AVAILABLE  NODE SELECTOR  AGE
kube2iam  5        5        0      5           0          <none>         2s

==> v1/Pod(related)
NAME            READY  STATUS             RESTARTS  AGE
kube2iam-754dm  0/1    ContainerCreating  0         2s
kube2iam-95mz8  0/1    ContainerCreating  0         2s
kube2iam-klhtc  0/1    ContainerCreating  0         2s
kube2iam-m9v5z  0/1    ContainerCreating  0         2s
kube2iam-xvkvt  0/1    ContainerCreating  0         2s


NOTES:
To verify that kube2iam has started, run:

  kubectl --namespace=kube-system get pods -l "app=kube2iam,release=kube2iam"

Add an iam.amazonaws.com/role annotation to your pods with the role you want them to assume.

  https://github.com/jtblin/kube2iam#kubernetes-annotation

Use `curl` to verify the pod's role from within:

  curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

Release "chart-repo" does not exist. Installing it now.
NAME:   chart-repo
E0418 14:46:49.898191     478 portforward.go:303] error copying from remote stream to local connection: readfrom tcp4 127.0.0.1:46183->127.0.0.1:41002: write tcp4 127.0.0.1:46183->127.0.0.1:41002: write: broken pipe
LAST DEPLOYED: Wed Apr 18 14:46:47 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME                TYPE    DATA  AGE
chart-repo-gateway  Opaque  2     1s
chart-repo-server   Opaque  2     1s

==> v1/Service
NAME                TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)   AGE
chart-repo-gateway  ClusterIP  100.68.33.126  <none>       8080/TCP  1s
chart-repo-server   ClusterIP  100.64.249.2   <none>       8080/TCP  1s

==> v1beta1/Deployment
NAME                DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
chart-repo-gateway  2        2        2           0          1s
chart-repo-server   2        2        2           0          1s

==> v1beta1/Ingress
NAME                HOSTS                                       ADDRESS  PORTS  AGE
chart-repo-gateway  gateway.charts.us-west-2.prod.cloudposse.co  80, 443  1s
chart-repo-server   charts.us-west-2.prod.cloudposse.co          80, 443  1s

==> v1/Pod(related)
NAME                               READY  STATUS             RESTARTS  AGE
chart-repo-gateway-b947dd69-jgf7c  0/1    ContainerCreating  0         1s
chart-repo-gateway-b947dd69-v8n6n  0/1    ContainerCreating  0         1s
chart-repo-server-d447dfdb6-4bbzn  0/1    ContainerCreating  0         1s
chart-repo-server-d447dfdb6-kfsl8  0/1    ContainerCreating  0         1s


NOTES:
Thank you for installing chart-repo.

Your release is named chart-repo.

Release "ingress" does not exist. Installing it now.
NAME:   ingress
LAST DEPLOYED: Wed Apr 18 14:46:48 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                             DATA  AGE
ingress-nginx-default-ba-config  1     2s
ingress-nginx-default-ba         2     2s
ingress-nginx-ingress            2     2s

==> v1/Service
NAME                      TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                     AGE
ingress-nginx-default-ba  ClusterIP     100.67.227.42   <none>       80/TCP                      2s
ingress-nginx-ingress     LoadBalancer  100.69.186.114  <pending>    80:32182/TCP,443:30549/TCP  2s

==> v1beta1/Deployment
NAME                      DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
ingress-nginx-default-ba  2        2        2           0          2s
ingress-nginx-ingress     4        4        4           0          2s

==> v1/Pod(related)
NAME                                      READY  STATUS             RESTARTS  AGE
ingress-nginx-default-ba-f6fd8b978-fj2zx  0/1    ContainerCreating  0         2s
ingress-nginx-default-ba-f6fd8b978-jx9t6  0/1    ContainerCreating  0         2s
ingress-nginx-ingress-76bc4ff7cc-4knmh    0/1    ContainerCreating  0         2s
ingress-nginx-ingress-76bc4ff7cc-4mplg    0/1    ContainerCreating  0         2s
ingress-nginx-ingress-76bc4ff7cc-8rwqz    0/1    ContainerCreating  0         2s
ingress-nginx-ingress-76bc4ff7cc-96v82    0/1    ContainerCreating  0         2s


Release "external-dns" does not exist. Installing it now.
NAME:   external-dns
LAST DEPLOYED: Wed Apr 18 14:46:48 2018
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME          TYPE    DATA  AGE
external-dns  Opaque  3     1s

==> v1/Service
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
external-dns  ClusterIP  100.68.153.195  <none>       7979/TCP  1s

==> v1beta1/Deployment
NAME          DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
external-dns  1        1        1           0          1s

==> v1/Pod(related)
NAME                           READY  STATUS             RESTARTS  AGE
external-dns-7bb969cf47-xdxzf  0/1    ContainerCreating  0         1s


NOTES:
To verify that external-dns has started, run:

  kubectl --namespace=kube-system get pods -l "app=external-dns,release=external-dns"

```


Verify that all deployed Kubernetes resources are up and running

```
✅   (cpco-prod-admin) kops ➤  kube-system get pods
NAME                                                                   READY     STATUS    RESTARTS   AGE
calico-kube-controllers-6b5f557d7d-lm2x7                               1/1       Running   0          9d
calico-node-5txbt                                                      2/2       Running   0          9d
calico-node-9mpgm                                                      2/2       Running   0          9d
calico-node-cx777                                                      2/2       Running   0          9d
calico-node-gcswp                                                      2/2       Running   0          9d
calico-node-nqmch                                                      2/2       Running   0          9d
chart-repo-gateway-b947dd69-jgf7c                                      1/1       Running   2          1m
chart-repo-gateway-b947dd69-v8n6n                                      1/1       Running   2          1m
chart-repo-server-d447dfdb6-4bbzn                                      1/1       Running   2          1m
chart-repo-server-d447dfdb6-kfsl8                                      1/1       Running   2          1m
dns-controller-6ddf5d44d5-l92c8                                        1/1       Running   0          9d
etcd-server-events-ip-172-20-127-167.us-west-2.compute.internal        1/1       Running   0          9d
etcd-server-events-ip-172-20-38-15.us-west-2.compute.internal          1/1       Running   0          9d
etcd-server-events-ip-172-20-73-251.us-west-2.compute.internal         1/1       Running   0          9d
etcd-server-ip-172-20-127-167.us-west-2.compute.internal               1/1       Running   0          9d
etcd-server-ip-172-20-38-15.us-west-2.compute.internal                 1/1       Running   0          9d
etcd-server-ip-172-20-73-251.us-west-2.compute.internal                1/1       Running   0          9d
external-dns-7bb969cf47-xdxzf                                          1/1       Running   0          1m
ingress-nginx-default-ba-f6fd8b978-fj2zx                               1/1       Running   0          1m
ingress-nginx-default-ba-f6fd8b978-jx9t6                               1/1       Running   0          1m
ingress-nginx-ingress-76bc4ff7cc-4knmh                                 1/1       Running   0          1m
ingress-nginx-ingress-76bc4ff7cc-4mplg                                 1/1       Running   0          1m
ingress-nginx-ingress-76bc4ff7cc-8rwqz                                 1/1       Running   0          1m
ingress-nginx-ingress-76bc4ff7cc-96v82                                 1/1       Running   0          1m
kube-apiserver-ip-172-20-127-167.us-west-2.compute.internal            1/1       Running   0          9d
kube-apiserver-ip-172-20-38-15.us-west-2.compute.internal              1/1       Running   0          9d
kube-apiserver-ip-172-20-73-251.us-west-2.compute.internal             1/1       Running   2          9d
kube-controller-manager-ip-172-20-127-167.us-west-2.compute.internal   1/1       Running   0          9d
kube-controller-manager-ip-172-20-38-15.us-west-2.compute.internal     1/1       Running   0          9d
kube-controller-manager-ip-172-20-73-251.us-west-2.compute.internal    1/1       Running   0          9d
kube-dns-7f56f9f8c7-62hbv                                              3/3       Running   0          9d
kube-dns-7f56f9f8c7-kq2c9                                              3/3       Running   0          9d
kube-dns-autoscaler-f4c47db64-hcss2                                    1/1       Running   0          9d
kube-lego-kube-lego-d88d9c968-kr94m                                    1/1       Running   0          1m
kube-proxy-ip-172-20-127-167.us-west-2.compute.internal                1/1       Running   0          9d
kube-proxy-ip-172-20-38-15.us-west-2.compute.internal                  1/1       Running   0          9d
kube-proxy-ip-172-20-43-225.us-west-2.compute.internal                 1/1       Running   0          9d
kube-proxy-ip-172-20-73-251.us-west-2.compute.internal                 1/1       Running   0          9d
kube-proxy-ip-172-20-89-216.us-west-2.compute.internal                 1/1       Running   0          9d
kube-scheduler-ip-172-20-127-167.us-west-2.compute.internal            1/1       Running   0          9d
kube-scheduler-ip-172-20-38-15.us-west-2.compute.internal              1/1       Running   0          9d
kube-scheduler-ip-172-20-73-251.us-west-2.compute.internal             1/1       Running   0          9d
kube2iam-754dm                                                         1/1       Running   0          1m
kube2iam-95mz8                                                         1/1       Running   0          1m
kube2iam-klhtc                                                         1/1       Running   0          1m
kube2iam-m9v5z                                                         1/1       Running   0          1m
kube2iam-xvkvt                                                         1/1       Running   0          1m
tiller-deploy-f44659b6c-dn6p2                                          1/1       Running   0          9d
```



## Related Projects

Check out these related projects.

- [Packages](https://github.com/cloudposse/packages) - Cloud Posse installer and distribution of native apps
- [Build Harness](https://github.com/cloudposse/dev) - Collection of Makefiles to facilitate building Golang projects, Dockerfiles, Helm charts, and more
- [terraform-root-modules](https://github.com/cloudposse/terraform-root-modules) - Collection of Terraform "root module" invocations for provisioning reference architectures
- [root.cloudposse.co](https://github.com/cloudposse/root.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Parent ("Root") Organization in AWS.
- [audit.cloudposse.co](https://github.com/cloudposse/audit.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for an Audit Logs Organization in AWS.
- [prod.cloudposse.co](https://github.com/cloudposse/prod.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Production Organization in AWS.
- [staging.cloudposse.co](https://github.com/cloudposse/staging.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Staging Organization in AWS.
- [dev.cloudposse.co](https://github.com/cloudposse/dev.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Development Sandbox Organization in AWS.




## References

For additional context, refer to some of these links. 

- [Cloud Posse Documentation](https://docs.cloudposse.com) - Complete documentation for the Cloud Posse solution
- [Chamber](https://docs.cloudposse.com/tools/chamber/) - Chamber is a CRUD tool for managing secrets stored in AWS Systems Manager Parameter Store and exposing those secrets as Environment Variables to processes.
- [The Right Way to Store Secrets using Parameter Store](https://aws.amazon.com/blogs/mt/the-right-way-to-store-secrets-using-parameter-store/) - Centrally and securely manage secrets with Amazon EC2 Systems Manager Parameter Store, lots of Terraform code, and chamber. This post has all the information you need to get running with Parameter Store in production.
- [external-dns](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/faq.md) - Frequently asked Questions & Answers
- [Kubernetes Production Patterns](https://github.com/gravitational/workshop/blob/master/k8sprod.md) - Explore helpful techniques to improve resiliency and high availability of Kubernetes deployments and will take a look at some common mistakes to avoid when working with Docker and Kubernetes.


## Help

**Got a question?**

File a GitHub [issue](https://github.com/cloudposse/prod.cloudposse.co/issues), send us an [email][email] or join our [Slack Community][slack].

## Commerical Support

Work directly with our team of DevOps experts via email, slack, and video conferencing. 

We provide *commercial support* for all of our [Open Source][github] projects. As a *Dedicated Support* customer, you have access to our team of subject matter experts at a fraction of the cost of a fulltime engineer. 

[![E-Mail](https://img.shields.io/badge/email-hello@cloudposse.com-blue.svg)](mailto:hello@cloudposse.com)

- **Questions.** We'll use a Shared Slack channel between your team and ours.
- **Troubleshooting.** We'll help you triage why things aren't working.
- **Code Reviews.** We'll review your Pull Requests and provide constructive feedback.
- **Bug Fixes.** We'll rapidly work to fix any bugs in our projects.
- **Build New Terraform Modules.** We'll develop original modules to provision infrastructure.
- **Cloud Architecture.** We'll assist with your cloud strategy and design.
- **Implementation.** We'll provide hands on support to implement our reference architectures. 


## Community Forum

Get access to our [Open Source Community Forum][slack] on Slack. It's **FREE** to join for everyone! Our "SweetOps" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build *sweet* infrastructure.

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/prod.cloudposse.co/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or [help out](https://github.com/orgs/cloudposse/projects/3) with our other projects, we would love to hear from you! Shoot us an [email](mailto:hello@cloudposse.com).

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!


## Copyright

Copyright © 2017-2018 [Cloud Posse, LLC](https://cloudposse.com)



## License 

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) 

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.









## Trademarks

All other trademarks referenced herein are the property of their respective owners.

## About

This project is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know at <hello@cloudposse.com>

[![Cloud Posse](https://cloudposse.com/logo-300x69.svg)](https://cloudposse.com)

We're a [DevOps Professional Services][hire] company based in Los Angeles, CA. We love [Open Source Software](https://github.com/cloudposse/)!

We offer paid support on all of our projects.  

Check out [our other projects][github], [apply for a job][jobs], or [hire us][hire] to help with your cloud strategy and implementation.

  [docs]: https://docs.cloudposse.com/
  [website]: https://cloudposse.com/
  [github]: https://github.com/cloudposse/
  [jobs]: https://cloudposse.com/jobs/
  [hire]: https://cloudposse.com/contact/
  [slack]: https://slack.cloudposse.com/
  [linkedin]: https://www.linkedin.com/company/cloudposse
  [twitter]: https://twitter.com/cloudposse/
  [email]: mailto:hello@cloudposse.com


