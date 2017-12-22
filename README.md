# drupal

## Corpusops doc (deployment)

### Setup variables
```sh
export A_GIT_URL="https://gitlab.foo.net/group/app.git"
export COPS_CWD="$HOME/makina/irstea/dinamis"
export NONINTERACTIVE=1
# VM NOT DONE
export FTP_URL=<tri>@/path
```
### Clone the project
- Note the **--recursive** switch; if you follow the next commands, you can then skip this step on the next docs.

    ```sh
    git clone --recursive $A_GIT_URL $COPS_CWD
    cd $COPS_CWD
    git submodule init
    git submodule update
    .ansible/scripts/download_corpusops.sh
    .ansible/scripts/setup_ansible.sh
    ```

### Deploy the dev VM
- [corpusops vagrant doc](https://github.com/corpusops/corpusops.bootstrap/blob/master/doc/projects/vagrant.md)<br/>
  or ``local/corpusops.bootstrap/doc/projects/vagrant.md`` after corpusops.bootstrap download.

### Deploy on enviromnents
- Setup needed when you dont have Ci setup for doing it for you
- [corpusops deploy doc](https://github.com/corpusops/corpusops.bootstrap/blob/master/doc/projects/deploy.md)<br/>
  or ``local/corpusops.bootstrap/doc/projects/deploy.md`` after corpusops.bootstrap download.

