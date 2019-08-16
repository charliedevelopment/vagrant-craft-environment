#!/bin/bash
# This script runs craft-reset.sh from the HOST on the GUEST.
# craft-reset.sh sets up Craft, removing any existing database and workspace if necessary.
# Pass `soft` as the first parameter if the Craft DB should be cleared and Craft reinstalled
# without removal/reset of any files.
# It is only for convenience running from the HOST.

ssh vagrant@192.168.33.10 -t -i .vagrant/machines/default/virtualbox/private_key "/setup/craft-reset.sh \"$@\""
