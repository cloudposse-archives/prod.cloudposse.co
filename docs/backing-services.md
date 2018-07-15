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
