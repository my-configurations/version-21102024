# .bash_profile

 

# Get the aliases and functions

if [ -f ~/.bashrc ]; then

        . ~/.bashrc

fi

 

# User specific environment and startup programs

 

# Kubectl shell completion

#source '/home/sysadm/.kube/completion.bash.inc'

 
 

 
#!/bin/bash

__oc_ps1()

{

    # Get current context



    CONTEXT=$(oc config view -o "jsonpath={.contexts[?(@.name==\"$(oc config view -o "jsonpath={\$.current-context}")\")].context.namespace}") 2> /dev/null 

    Clustername=$(kubectl config current-context | cut -d '/' -f2 | cut -d '-' -f2,3) 2> /dev/null



    if [ -n "$CONTEXT" ]; then

        echo "(${Clustername}:${CONTEXT})"

    fi

}

alias o='oc'

alias n='oc get node'
alias oke="export KUBECONFIG=/home/gamasy/oke/kubeconfig"
alias b="export KUBECONFIG=/home/gamasy/mnc2/kubeconfig"
alias a="export KUBECONFIG=/home/gamasy/mnc1/kubeconfig"
alias 1="export KUBECONFIG=/home/gamasy/acm1/kubeconfig"
alias 2="export KUBECONFIG=/home/gamasy/acm2/kubeconfig"

export acm1=/home/gamasy/acm1/gamasy
export acm2=/home/gamasy/acm2/gamasy
export mnc1=/home/gamasy/mnc1/gamasy
export mnc2=/home/gamasy/mnc2/gamasy
export oke=/home/gamasy/oke/gamasy

alias nw='oc get node -o wide'

alias po='oc get pods'

alias svc='oc get svc'

alias ocw='oc whoami'

alias deploy='oc get deployment'

alias rs='oc get replicaset'

alias ds='oc get daemonsets'

alias createf='oc create -f'

alias project='oc get projects'

alias podw='oc get pods -o wide'

alias login="oc login -u XXXXXX -p XXXXXX'"

alias k9s=~/k9s.sh

alias ldappass="echo QUtSITIxPHk= | base64 -d"

alias event='oc get events --sort-by='.lastTimestamp' -w '

alias disk="oc get node -o json | jq '.items[] | { name: .metadata.name, conditions: .status.conditions[] } | select ((.conditions.type | contains("Pressure")) and .conditions.status != "False")'"

alias drain="oc adm drain "$1" "$2" "$3" "$4" "$5" --delete-local-data --ignore-daemonsets  --force --grace-period=0 --delete-emptydir-data"

alias uncordon=" oc adm uncordon "$1" "$2" "$3" "$4" "$5" "

 

# $1 is kind (User, Group, ServiceAccount)

# $2 is name ("system:nodes", etc)

# $3 is namespace (optional, only applies to kind=ServiceAccount)

 

#functions

 

 

node-number(){

 

if oc auth can-i get nodes -A >/dev/null 2>&1; then

  echo "Masters: $(oc get nodes -o name --no-headers --selector='node-role.kubernetes.io/master' | wc -l)"

  echo  "Workers: $(oc get nodes -o name --no-headers --selector='node-role.kubernetes.io/worker' | wc -l)"

  echo "Infras: $(oc get nodes -o name --no-headers --selector='node-role.kubernetes.io/infra' | wc -l)"

  echo "Total nodes: $(oc get nodes -o name --no-headers | wc -l)"

  exit ${OCINFO}

else

  echo "Couldn't get nodes, check permissions"

  exit ${OCSKIP}

fi

exit ${OCUNKNOWN}

 

 

}

 

pod-notrunning(){

 

 

 

error=false

 

if oc auth can-i get pods -A >/dev/null 2>&1; then

  # Get all nonrunning pods with headers even if they are not found

  notrunning=$(oc get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --ignore-not-found=true)

  HEADER=$(echo "${notrunning}" | head -n1)

  PODS=$(echo "${notrunning}" | tail -n +2)

  if [[ -n ${PODS} ]]; then

    echo "Pods not running ($(echo "${PODS}" | wc -l)):\n${HEADER}\n${RED}${PODS}${NOCOLOR}"

#    errors=$(("${errors}" + 1))

#    error=true

  fi

  if [ ! -z "${ERRORFILE}" ]; then

    echo $errors >${ERRORFILE}

  fi

  if [[ "$error" == true ]]; then

    exit ${OCERROR}

  else

    exit ${OCOK}

  fi

 

else

  echo  "Couldn't get all pods, check permissions"

  exit ${OCSKIP}

fi

exit ${OCUNKNOWNN}

 

}

 

 

node-status(){

 

if oc auth can-i get nodes >/dev/null 2>&1; then

  nodes_not_ready=$(oc get nodes -o json | jq '.items[] | { name: .metadata.name, type: .status.conditions[] } | select ((.type.type == "Ready") and (.type.status != "True"))')

  if [[ -n ${nodes_not_ready} ]]; then

    NODESNOTREADY=$(echo "${nodes_not_ready}" | jq .)

    echo "Nodes ${RED}NotReady${NOCOLOR}: ${NODESNOTREADY}"

#    errors=$(("${errors}" + 1))

#    error=true

  fi

  disabled_nodes=$(oc get nodes -o json | jq '.items[] | { name: .metadata.name, status: .spec.unschedulable } | select (.status == true)')

  if [[ -n ${disabled_nodes} ]]; then

    NODESDISABLED=$(echo "${disabled_nodes}" | jq .)

    echo "Nodes ${RED}Disabled${NOCOLOR}: ${NODESDISABLED}"

#    errors=$(("${errors}" + 1))

#    error=true

  fi

  pressure_nodes=$(oc get node -o json | jq '.items[] | { name: .metadata.name, conditions: .status.conditions[] } | select ((.conditions.type | contains("Pressure")) and .conditions.status != "False")')

  if [[ -n ${pressure_nodes} ]]; then

    NODESPRESSURE=$(echo "${pressure_nodes}" | jq .)

    echo "Nodes with ${RED}Pressure${NOCOLOR}: ${NODESPRESSURE}"

#    errors=$(("${errors}" + 1))

  fi

  if [ ! -z "${ERRORFILE}" ]; then

    echo $errors >${ERRORFILE}

  fi

  if [[ "$error" == true ]]; then

    exit ${OCERROR}

  else

    exit ${OCOK}

  fi

 

else

  echo "Couldn't get nodes, check permissions"

  exit ${OCSKIP}

fi

echo "finished"

}

 

 

forloop(){     for node in $(oc get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do         echo $node; ssh  -o ConnectTimeout=5 -i  /home/gamasy/id_ed25519  core@${node} ""$@""; echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";     done; }

 

function getRoles() {

    local kind="${1}"

    local name="${2}"

    local namespace="${3:-}"

 

    oc get clusterrolebinding -o json | jq -r "

      .items[]

      |

      select(

        .subjects[]?

        |

        select(

            .kind == \"${kind}\"

            and

            .name == \"${name}\"

            and

            (if .namespace then .namespace else \"\" end) == \"${namespace}\"

        )

      )

      |

      (.roleRef.kind + \"/\" + .roleRef.name)

    "

}
