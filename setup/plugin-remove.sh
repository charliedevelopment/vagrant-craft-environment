# This script uninstalls Composer package (Craft plugin).
# It should be run from the vagrant environment folder of the HOST with the following options:
#
# plugin-remove.sh package/name

# Get write control of all files, (mostly for sync issues and git permission errors (possibly a Windows only issue?)).
# Then remove the plugin.
ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
chmod -R u+w /var/www/vendor/$1
composer remove $1
EOF