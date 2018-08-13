# docker build --squash -t <your/project> . -f Dockerfile --build-arg=SKIP_COPS_UPDATE=y
FROM corpusops/ubuntu:16.04
# Rewarm apt cache
RUN bash -c '\
  if egrep -qi "ubuntu|mint|debian" /etc/*-release 2>/dev/null;then\
      apt-get update -y -qq;\
      if [ "x${PKGS_REMOVES-}" != "x" ];then\
        apt-get install -y $PKGS_REMOVES;\
      fi;\
  fi'
WORKDIR /provision_dir
# Way to override var from upper image (already defined)
ARG APP_ENV_NAME=docker
ARG COPS_PROJECT_TYPE=drupal
ARG COPS_DB_TYPE=postgresql
ARG SKIP_COPS_UPDATE=
ARG COPS_ANCESTOR=setups.${COPS_PROJECT_TYPE}
ARG TMPPLAYBOOK=.ansible/playbooks/bootstrap.yml
ENV A_ENV_NAME=$APP_ENV_NAME
ENV COPS_PROJECT_TYPE=$COPS_PROJECT_TYPE
ENV TMPPLAYBOOK=$TMPPLAYBOOK
ENV NONINTERACTIVE=1
ARG DEFAULT_A_INVENTORY="localhost,"
ENV A_INVENTORY=$DEFAULT_A_INVENTORY

## Uncomment to load inside the container
## local corpusops.bootstrap modifications
## rm local/corpusops.bootstrap;sudo mount -o bind ~/corpusops/corpusops.bootstrap local/corpusops.bootstrap
#ADD local/corpusops.bootstrap/hacking $COPS_ROOT/hacking/
#ADD local/corpusops.bootstrap/bin     $COPS_ROOT/bin/
#ADD local/corpusops.bootstrap/roles   $COPS_ROOT/roles/

# setup app (without services and content managment)
ADD . /provision_dir
RUN bash -c '\
  rm -rf local/corpusops.bootstrap \
  && ln -sf $COPS_ROOT local/corpusops.bootstrap \
  && .ansible/scripts/download_corpusops.sh \
  && .ansible/scripts/setup_ansible.sh'

# setup app (without services and content managment)
ADD . /provision_dir
RUN bash -c '\
  rm -rf local/corpusops.bootstrap \
  && ln -sf $COPS_ROOT local/corpusops.bootstrap \
  && .ansible/scripts/download_corpusops.sh \
  && .ansible/scripts/setup_ansible.sh'

### Install db server but ensure that services wont be started through packages
RUN bash -c '\
  $COPS_ROOT/hacking/docker_toggle_pm on \
  && : "install db server" \
  && $_call_ansible .ansible/playbooks/db.yml \
  -e "{corpusops_services_db_mysql_do_fix_encoding: false, \
       corpusops_services_db_mysql_do_services: false, \
       cops_${COPS_DB_TYPE}_s_entry_point: false, \
       cops_${COPS_DB_TYPE}_s_healthchecks: false, \
       cops_${COPS_DB_TYPE}_s_manage_content: false }" \
  && $COPS_ROOT/hacking/docker_toggle_pm off'

### Install elasticsearch server but ensure that services wont be started through packages
RUN bash -c '\
  : "install elasticsearch server" \
  && $_call_ansible .ansible/playbooks/elasticsearch.yml \
  -e "{cops_elasticsearch_s_entry_point: false, \
       cops_elasticsearch_s_healthchecks: false, \
       cops_elasticsearch_s_manage_content: false }"'

# Install drupal app
RUN bash -c '\
  $_call_ansible .ansible/playbooks/app.yml \
  -e "{cops_${COPS_PROJECT_TYPE}_s_healthchecks: false, \
       cops_${COPS_PROJECT_TYPE}_s_setup_test_build: true,\
       cops_${COPS_PROJECT_TYPE}_s_manage_content: false}"'

# Install sidecar dbsmartbackup
RUN bash -c '\
  $_call_ansible .ansible/playbooks/db_backup.yml \
  -e "{cops_dbsmartbackup_s_manage_content: false, \
       cops_dbsmartbackup_s_entry_point: false}"'


# Default to launch systemd, and you ll have have to mount:
#  -v /sys/fs/cgroup:/sys/fs/cgroup:ro
STOPSIGNAL SIGRTMIN+3
CMD ["/app_entry_point"]
# pack, cleanup, snapshot any found git repo
RUN bash -c 'step_rev=3;set -e;cd $COPS_ROOT;\
    GIT_SHALLOW_DEPTH=1 \
    GIT_SHALLOW=y \
    NO_IMAGE_STRIP= /sbin/cops_container_strip.sh;'
