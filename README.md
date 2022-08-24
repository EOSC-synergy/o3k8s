# o3k8s

[HELM](https://helm.sh/) chart for the O3as deployment in Kubernetes.

Installs: [o3api](https://git.scc.kit.edu/synergy.o3as/o3api) and [o3webapp](https://git.scc.kit.edu/synergy.o3as/o3webapp)

Recommended command to install the chart:

in the "test" environment:
```sh
helm install o3as-app o3as-app --create-namespace --namespace o3as --values o3as-app/values-test.yaml
```

in the "production" environment:
```sh
helm install o3as-app o3as-app --create-namespace --namespace o3as --values o3as-app/values-test.yaml
```

to uninstall:
```sh
helm uninstall o3as-app -n o3as
```

