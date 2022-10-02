#!/usr/bin/env bash

KUBECONFIG=$HOME/.kube/config

# o3as helm chart settings
repo="o3k8s"
pv="pv-o3as"
ns="o3as"
secret="o3as-secrets"
helm="o3as-app"
pvc="o3as-pvc"

# 1. Check that pv-o3as exists
pv_status=$(kubectl get pv |grep ${pv}|cut -d' ' -f1)

if [ "${pv_status}" == "${pv}" ]; then
   echo "[OK] PersistentVolume \"$pv\" is found"
else
   echo "[FAIL] You have to create \"$pv\" PersistentVolume on kubernetes first!"
   exit 1
fi

# 2. Check that o3as namespace exists
ns_status=$(kubectl get ns |grep $ns|cut -d' ' -f1)

if [ "${ns_status}" == "$ns" ]; then
   echo "[OK] Namespace \"$ns\" is found"
else
   echo "[FAIL] You have to create \"$ns\" Namespace on kubernetes first!"
   exit 2
fi

# 3. Check if o3as secret exists in o3as namespace
secret_status=$(kubectl get secrets -n $ns |grep $secret |cut -d' ' -f1)
if [ "${secret_status}" == "$secret" ]; then
   echo "[OK] Secret \"$secret\" is found in the namespace $ns"
else
   echo "[FAIL] You have to create \"$secret\" Secret in the $ns Namespace on kubernetes first!"
   exit 3
fi

helm_status=$(helm list -n $ns -q)
if [ "${helm_status}" == "$helm" ]; then
   echo "[WARNING] Helm App \"$helm\" is already deployed. Trying to deprovision it now.."
   status=$(helm uninstall $helm -n $ns)
   sleep 10
   # we need to patch PVC, see e.g.
   # https://veducate.co.uk/kubernetes-pvc-terminating/
   # https://github.com/kubernetes/kubernetes/issues/69697
   kubectl patch pvc $pvc -n $ns -p '{"metadata":{"finalizers":null}}'
   echo $status
   # once PVC is deleted, PV has to be unbound
   echo "[WARNING] Resetting  PersistentVolume"
   pv_status=$(kubectl patch pv $pv -p '{"spec":{"claimRef": null}}')
   echo $pv_status
fi

echo "[INFO] Let's lint the HELM chart, $helm"
helm lint $helm ${HOME}/${repo}/$helm --values ${HOME}/${repo}/$helm/values-test.yaml

echo "[INFO] Trying to deploy Helm App \"$helm\".."
helm install $helm ${HOME}/${repo}/$helm --namespace $ns --values ${HOME}/${repo}/$helm/values-test.yaml
