# o3k8s

[HELM](https://helm.sh/) chart for the O3as deployment in Kubernetes.

Installs: [o3api](https://git.scc.kit.edu/synergy.o3as/o3api) and [o3webapp](https://git.scc.kit.edu/synergy.o3as/o3webapp)

## Pre-requisites 
### k8s admin actions

1. cert-manager has to be installed in the cluster, see [cert-manager documentation](https://cert-manager.io/docs/), or
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
```

2. [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PV) has to be created, e.g. named "pv-o3as".

   There are two examples in the repository:
   * hostPath (single node cluster): `pv-o3as-hostpath.yml`
   * NFS case: `pv-o3as-nfs.yml` <br>
   **NB!** NFS server has to be installed, configured and running!

3. Namespace "o3as" has to be created, `kubectl create ns o3as`

### nsupdate configuration
Deployed service benefits from the [Dynamic DNS service](https://nsupdate.fedcloud.eu/) (aka nsupdate) for EGI federated cloud.
One has to configure domain name using [nsupdate](https://nsupdate.fedcloud.eu/) and obtain corresponding token.

## How to install the chart via Helm:

!! **DON'T FORGET** to configure secrets (e.g. for nsupdate token) !! See `secrets.yml.tmpl`

Install in the "test" environment:
```sh
helm install o3as-app o3as-app --namespace o3as --values o3as-app/values-test.yaml
```

Install in the "production" environment:
```sh
helm install o3as-app o3as-app --namespace o3as --values o3as-app/values-prod.yaml
```

to uninstall:
```sh
helm uninstall o3as-app -n o3as
```

## How to deploy/undeploy via "deploy" script
In the repository there is `deploy.sh` (or `deploy`) which performs a number of checks before the actual deployment:

1. helm lint to check the chart

2. Check that "pv-o3as" PersistentVolume exists

3. Check that "o3as" Namespace exists

4. Check if o3as secret exists in o3as namespace

5. Check if Helm chart already deployed, if so => undeploy

6. Finally, deploy the chart

There is also option to **undeploy** the chart. The current options include:

```
Usage: deploy <options>

    Options:
    -h|--help 		 This help message
    -p|--prod 		 Deploy Helm chart o3as-app in the production environment
    -s|--stage 		 Deploy Helm chart o3as-app in the staging environment
    -t|--test 		 Deploy Helm chart o3as-app in the test environment
    -u|--undeploy 	 Undeploy Helm chart o3as-app
```

The script is also intended to simplify CI/CD for the service.

