#!/usr/bin/env bash
. "$(dirname ${0})/base.sh"
cd "${WWW_DIR}"
chmod u+w "${WWW_DIR}/sites/"*
do_make=""
# run make only if one of those tests is valid in this order:
# - the presence of a file "$FORCE_MAKE_MARKER
# - the environment $FORCE_MAKE to be a non empty string
# - one of the modules in $MODULES_CHECK is absent
if [ "x${FORCE_MAKE}" != "x0" ] && [ "x${FORCE_MAKE}" != "x" ];then
    do_make="y"
elif test -e "${FORCE_MAKE_MARKER}";then
    do_make="y"
elif [ "x8" != "x${DRUPAL_VERSION}" ] && [ ! -e "${WWW_DIR}/sites/all/modules" ];then
    do_make="y"
else
    mdir="$(site_modules_dir)"
    for ff in ${MODULES_CHECK};do
        f="${mdir}/${ff}"
        if [ ! -e "${f}" ];then
            echo "${f} is missing"
            do_make="y"
        fi
    done
fi
if [ "x${do_make}" = "x" ];then
    echo "Make skipped"
    exit 0
fi
"${DRUSH}" make --concurrency=4 -y "$(drupal_profile)" ${EXTRA_DRUSH_MAKE_ARGS}
exit ${?}
