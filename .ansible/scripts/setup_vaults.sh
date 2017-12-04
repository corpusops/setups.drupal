#!/usr/bin/env bash
set -e

if [[ -n ${SKIP_VAULT_PASSWORD_FILES_SETUP-} ]];then
    echo "-> Skip ansible vault password files setup" >&2
    exit 0
fi

# Setup ansible vault password files if any (via gitlab secret variable)
# from each found CORPUSOPS_VAULT_PASSWORD_XXX
export VAULT_VARS=$( printenv \
    | egrep -oe "^CORPUSOPS_VAULT_PASSWORD_[a-zA-Z]+=" \
    | sed -e "s/=$//g"|awk '!seen[$0]++')
for vault_var in $VAULT_VARS;do
    vault_name="$(echo $vault_var \
        | awk -F CORPUSOPS_VAULT_PASSWORD_ '{print $2}')"
    val="$(echo "\$$vault_var")"
    f="$SECRET_VAULT_DIRECTORY.$vault_name"
    echo "setup $vault_name vault: ($f)"
    if [ -n $val ];then
        echo "$val" > "$f"
        chmod 600 "$f"
    fi
done
