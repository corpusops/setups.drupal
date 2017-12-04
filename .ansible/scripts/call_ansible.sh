#!/usr/bin/env bash
set -e
ci_cwd=$(pwd)
dryrun_vv() { echo "($ci_cwd) $@" >&2;echo "$@"; }
vv() { echo "($ci_cwd) $@" >&2;"$@"; }
debug() { if [[ -n "${ADEBUG-}" ]];then echo "$@" >&2;fi }
vaultpwfile=''
for SECRET_VAULT in $SECRET_VAULTS;do
    vault=$(echo "$SECRET_VAULT"|awk -F@ '{print $1}')
    if [ -e $vault ];then
        echo "-> Using vault: $vault" >&2
        if "$AP" --help|grep -q vault-id;then
            vaultpwfiles="--vault-id \"$vault\""
        else
            vaultpwfiles="--vault-password-file \"$vault\""
        fi
    else
        debug "No vault password found in $vault" >&2
    fi
done
do_="vv"
if [[ -n ${ANSIBLE_DRY_RUN-${DRY_RUN-}} ]];then
    do_="dryrun_vv"
fi
if [[ -z "${NO_SILENT-}" ]];then
  $do_ \
      $COPS_ROOT/bin/silent_run \
      $AP \
      --vault-password-file "/root/makina-drupal.solibre.staging"  \
      $A_INVENTORY \
      $A_CUSTOM_ARGS \
      ${PLAYBOOK_PRE_ARGS-} \
      ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
      $PLAYBOOK \
      ${PLAYBOOK_POST_ARGS-} \
      ${PLAYBOOK_POST_CUSTOM_ARGS-}
else
  $do_ \
      $AP \
      $vaultpwfile \
      $A_INVENTORY \
      $A_CUSTOM_ARGS \
      ${PLAYBOOK_PRE_ARGS-} \
      ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
      $PLAYBOOK \
      ${PLAYBOOK_POST_ARGS-} \
      ${PLAYBOOK_POST_CUSTOM_ARGS-}
fi
