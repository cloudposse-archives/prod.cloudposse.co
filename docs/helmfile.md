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
