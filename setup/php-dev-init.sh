# This script runs some additional provisioning for the purpose of PHP development.
# This script can be run manually at any time from the HOST.
# This script should only be run once.

ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key << EOF
# Install the PHP CodeSniffer package globally.
composer global require "squizlabs/php_codesniffer=*"
# Update vagrant's bash profile to add the composer's bin folder, for composer tools.
sed -i '/^PATH=\$PATH/ s/$/:\$HOME\/.config\/composer\/vendor\/bin/' ~/.bash_profile
# Update the current environment information from the profile.
source ~/.bash_profile
# Indicate to PHP CodeSniffer where PHP is installed, for the purpose of syntax checking.
phpcs --config-set php_path /usr/bin/php

# Install the PHP documentor.
# composer global require "phpdocumentor/phpdocumentor:2.*"
EOF