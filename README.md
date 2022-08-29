# o3k8s

[HELM](https://helm.sh/) chart for the O3as deployment in Kubernetes.

Installs: [o3api](https://git.scc.kit.edu/synergy.o3as/o3api) and [o3webapp](https://git.scc.kit.edu/synergy.o3as/o3webapp)

## K8s pre-requisites (k8s admin actions)

1. cert-manager has to be installed in the cluster, see [cert-manager](https://cert-manager.io/docs/), or
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
```

2. PersistentVolume has to be created, e.g. named "pv-o3as".

   There are two examples in the repository:
   * hostPath (single node cluster): pv-o3as-hostpath.yml
   * NFS case: pv-o3as-hostpath.yml
   NB! NFS server has to be installed, configured and running!

3. Namespace "o3as" has to be created, `kubectl create ns o3as´

## How to install the chart:

!! DON'T FORGET to configure secrets !! See secrets.yml.tmpl

in the "test" environment:
```sh
helm install o3as-app o3as-app --namespace o3as --values o3as-app/values-test.yaml
```

in the "production" environment:
```sh
helm install o3as-app o3as-app --namespace o3as --values o3as-app/values-prod.yaml
```

to uninstall:
```sh
helm uninstall o3as-app -n o3as
```

