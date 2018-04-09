#!/usr/bin/env bash
# Wrapper around behat test executable
pushd "`dirname $0`/.." > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# BEHAT=${SCRIPTPATH}/lib/vendor/behat/behat/bin/behat
BEHAT=${SCRIPTPATH}/vendor/bin/behat
AUTOLOAD=${SCRIPTPATH}/vendor/autoload.php
BEHAT_STUFF=${SCRIPTPATH}/tests
PROJECT_USER=$(stat -c '%U' ${BEHAT_STUFF}/behat.yml)

ps auxf|grep -v grep|grep -q Xvnc4
if [ "x${?}" == "x0" ]; then
    echo "VNC Server already running"
else
    echo "Starting VNC Server (for firefox-selenium)"
    if [ "x${USER}" != "x${PROJECT_USER}" ]; then
        if [ "x${USER}" == "xroot" ]; then
            su -c "vncserver -httpport 5901 -depth 16 -geometry 1280x1024 :1
            -localhost=0" $PROJECT_USER
        else
            echo "We cannot start vncserver as ${PROJECT_USER} (not root). We'll try with current user, hope things will work..."
            vncserver -httpport 5901 -depth 16 -geometry 1280x1024 :1 -localhost=0
        fi
    else
        vncserver -httpport 5901 -depth 16 -geometry 1280x1024 :1 -localhost=0
    fi
fi

# here is the most important thing (no chdir() in behat)
# and the commend MUSt be running in the behat.yml directory
cd ${BEHAT_STUFF}
${BEHAT} "$@"

#echo "Stopping VNC Server (for firefox-selenium)"
#vncserver -kill :1

# vim:set et sts=4 ts=4 tw=80:

