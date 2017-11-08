#!/usr/bin/env bash
# {{ansible_managed}}
# {% set d = cops_drupal_vars %}
set -ex
# Usually we will use this script twice upon the image start
# - one to reconfigure files before systemd and the service start
# - a second time after init, use case is eg to create dbs after
#   services are up, with then different skip tags
# The trick reside to use env var to control what the script will do

DEFAULT_ANSIBLE_VAULTS="{{d.ep_vaults|join(' ')}}"
export ANSIBLE_VAULTS="${ANSIBLE_VAULTS-${DEFAULT_ANSIBLE_VAULTS}}"
export ANSIBLE_VARARGS="${ANSIBLE_VARARGS-}"
export ANSIBLE_FOLDER="${ANSIBLE_FOLDER-ansible}"
export SKIP_TAGS_MODE="${SKIP_TAGS_MODE-${1:-}}"
export ANSIBLE_PLAY="${ANSIBLE_PLAY-{{d.ep_playbook}}}"
case $SKIP_TAGS_MODE in
    post)
        export ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS-{{d.ep_post_start_skip_tags}}}";;
    *)
        export ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS-{{d.ep_skip_tags}}}";;
esac

for i in $ANSIBLE_VAULTS;do
    if [ -e $i ];then
        ANSIBLE_VARARGS="-e @$i"
    fi
done
export ANSIBLE_VARARGS
if [[ -z ${NO_CONFIG-} ]];then
    cd /provision_dir
    if [[ -n "$ANSIBLE_FOLDER" ]] && [ -d "$ANSIBLE_FOLDER" ];then
        cd "$ANSIBLE_FOLDER"
    fi
    /srv/corpusops/corpusops.bootstrap/bin/cops_apply_role \
        $ANSIBLE_VARARGS \
        -vvvv "$ANSIBLE_PLAY" \
        --skip-tags=$ANSIBLE_SKIP_TAGS
fi
