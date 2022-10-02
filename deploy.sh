#!/usr/bin/env bash

KUBECONFIG=$HOME/.kube/config

# o3as helm chart settings
repo="o3k8s"                        # git repository name
pv="pv-o3as"                        # PersistentVolume allocated for o3as service
ns="o3as"                           # Namespace reserved for o3as service
secret="o3as-secrets"               # Secrets prepared for o3as service
pvc="o3as-pvc"                      # Name of the PersistentVolumeClaim
helm="o3as-app"                     # Name of the Helm  o3as chart
helm_values_prod="values.yaml"      # Values file for the Helm o3as chart
helm_values_stage="values.yaml"     # Values file for the Helm o3as chart
helm_values_test="values-test.yaml" # Values file for the Helm o3as chart

# Defaults
DEP_ENV_DEFAULT="test"              # default deployment environment
helm_values=$helm_values_test       # Default Values file for the Helm o3as chart
helm_set_values=""                  # By default no values to override
timeout="60s"                       # Default timeout for deployment

# Usage and command line parsing
function usage()
{
    shopt -s xpg_echo
    echo "Usage: $0 <options> \n
    Options:
    -h|--help \t\t This help message
    -p|--prod \t\t Deploy Helm chart $helm in the production environment
    -s|--stage \t\t Deploy Helm chart $helm in the staging environment
    -t|--test \t\t Deploy Helm chart $helm in the test environment
    -u|--undeploy \t Undeploy Helm chart $helm" 1>&2; exit 0;
}

function check_arguments()
{
    OPTIONS=h,p,s,t,u
    LONGOPTS=help,prod,stage,test,undeploy
    # https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
    #set -o errexit -o pipefail -o noclobber -o nounset
    set  +o nounset
    ! getopt --test > /dev/null
    if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
        echo '`getopt --test` failed in this environment.'
        exit 1
    fi

    # -use ! and PIPESTATUS to get exit code with errexit set
    # -temporarily store output to be able to check for errors
    # -activate quoting/enhanced mode (e.g. by writing out “--options”)
    # -pass arguments only via   -- "$@"   to separate them correctly
    ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # e.g. return value is 1
        #  then getopt has complained about wrong arguments to stdout
        exit 1
    fi
    # read getopt’s output this way to handle the quoting right:
    eval set -- "$PARSED"

    if [ "$1" == "--" ]; then
        echo "[INFO] No arguments provided, using defaults."
        DEP_ENV=$DEP_ENV_DEFAULT
    fi
    # now enjoy the options in order and nicely split until we see --
    while true; do
        case "$1" in
            -h|--help)
                usage
                shift
                ;;
            -p|--prod)
                DEP_ENV="prod"
                helm_values=${helm_values_prod}
                shift
                ;;
            -s|--stage)
                DEP_ENV="stage"
                helm_values=${helm_values_stage}
                helm_set_values=("--set letsencrypt.acme.server=https://acme-staging-v02.api.letsencrypt.org/directory\
                    --set sites.hostApi=o3api.test.fedcloud.eu\
                    --set sites.hostWeb=o3web.test.fedcloud.eu\
                    --set env.hdf5UseFileLocking=FALSE"
                )
                shift
                ;;
            -t|--test)
                DEP_ENV="test"
                helm_values=${helm_values_test}
                shift
                ;;
            -u|--undeploy)
                DEP_ENV="undeploy"
                helm_values=${helm_values_test}
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
            esac
        done
}

check_arguments "$0" "$@"
echo "Deployment ENV: $DEP_ENV"
echo "Helm values file: $helm_values"
echo "Helm --set values: $helm_set_values"

# function to undeploy Helm chart
undeploy()
{
   hlm=$1
   helm_status=$(helm list -n $ns -q)
   if [ "${helm_status}" == "$hlm" ]; then
      echo "[WARNING] Helm chart \"$hlm\" is already deployed. Trying to undeploy it now.."
      status=$(helm uninstall $hlm -n $ns)
      sleep 5
      echo $status
      # (force) delete corresponding PVC
      kubectl delete pvc $pvc -n $ns &
      sleep 5
   fi

   # we need to patch PVC, if it is in "Terminatiing" phase. See e.g.
   # https://veducate.co.uk/kubernetes-pvc-terminating/
   # https://github.com/kubernetes/kubernetes/issues/69697
   # if "Terminating" is found, try to reset
   while [ -n "$(kubectl get pvc -n $ns |grep $pvc |grep -i Terminating)" ];
   do
      kubectl patch pvc $pvc -n $ns -p '{"metadata":{"finalizers":null}}'
   done
   # once PVC is deleted, PV has to be unbound
   echo "[WARNING] Resetting  PersistentVolume, $pv"
   pv_status=$(kubectl patch pv $pv -p '{"spec":{"claimRef": null}}')
   echo $pv_status
}

if [ "$DEP_ENV" == "undeploy" ]; then
   undeploy $helm
   status=$?
   exit $status
fi

# 0. We first lint the HELM chart
echo "[INFO] Let's first lint the HELM chart, $helm"
cmd="helm lint ${HOME}/${repo}/$helm --values ${HOME}/${repo}/$helm/${helm_values}"
$cmd
if [ "$?" -gt 0 ]; then
  echo "[FAIL] Linting $helm Helm chart failed!"
  echo "       Command: ${cmd}"
  exit 1
fi

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
   exit 1
fi

# 3. Check if o3as secret exists in o3as namespace
secret_status=$(kubectl get secrets -n $ns |grep $secret |cut -d' ' -f1)
if [ "${secret_status}" == "$secret" ]; then
   echo "[OK] Secret \"$secret\" is found in the namespace $ns"
else
   echo "[FAIL] You have to create \"$secret\" Secret in the $ns Namespace on kubernetes first!"
   exit 1
fi

# 4. Check if Helm chart already undeployed, if so => undeploy
undeploy $helm

echo "[INFO] Trying to deploy Helm chart \"$helm\".."
# --wait may not be sufficient as it looks for 'maxUnavailable' which is 0 by default, see
# e.g. https://github.com/helm/helm/issues/3173
helm install --wait --timeout $timeout \
     $helm ${HOME}/${repo}/$helm \
     --namespace $ns \
     --values ${HOME}/${repo}/$helm/${helm_values} \
     $helm_set_values
