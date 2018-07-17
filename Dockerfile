FROM cloudposse/terraform-root-modules:0.4.5 as terraform-root-modules

FROM cloudposse/geodesic:0.11.6

ENV DOCKER_IMAGE="cloudposse/prod.cloudposse.co"
ENV DOCKER_TAG="latest"

ENV BANNER="prod.cloudposse.co"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="cpco-prod-admin"

# AWS Region for the cluster
ENV AWS_REGION="us-west-2"

# Terraform State Bucket
ENV TF_BUCKET="cpco-prod-terraform-state"
ENV TF_BUCKET_REGION="us-west-2"
ENV TF_DYNAMODB_TABLE="cpco-prod-terraform-state-lock"

# Terraform Vars
ENV TF_VAR_domain_name=prod.cloudposse.co
ENV TF_VAR_namespace=cpco
ENV TF_VAR_stage=prod

ENV TF_VAR_REDIS_INSTANCE_TYPE=cache.r3.large

# chamber KMS config
ENV CHAMBER_KMS_KEY_ALIAS="alias/cpco-prod-chamber"

# Copy root modules
COPY --from=terraform-root-modules /aws/ /conf/

# Place configuration in 'conf/' directory
COPY conf/ /conf/

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

# kops config
ENV KUBERNETES_VERSION="1.9.6"
ENV KOPS_CLUSTER_NAME="us-west-2.prod.cloudposse.co"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://cpco-prod-kops-state"
ENV KOPS_STATE_STORE_REGION="us-west-2"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="m4.large"
ENV NODE_MACHINE_TYPE="m4.large"
ENV NODE_MAX_SIZE="8"
ENV NODE_MIN_SIZE="8"

# Generate kops manifest
RUN build-kops-manifest

WORKDIR /conf/
