#!/bin/sh

. "`dirname $0`/get-paths.sh";

# Locate drush
# Try local drush install
DRUSH="$BINPATH/drush"
# Try global drush install
if [ ! -x ${DRUSH} ]
then
    if [ -f ${DRUSH} ]; then
        echo "ERROR: local drush exists but is not executable!"
        exit 1;
    fi
    echo "Local drush not found, trying the global one"
    DRUSH=`which drush`
fi
# Ask the user
while [ ! -x ${DRUSH} ]
   do
   read -p "Couldn't find drush. Where is drush? (absolute path) " DRUSH
   done
echo "Drush found at ${DRUSH}"

