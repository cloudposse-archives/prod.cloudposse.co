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
