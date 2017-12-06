# This script updates a Composer package (Craft plugin) from its underlying repository.
# It should be run from the `workspace` directory of the HOST with the following options:
#
# plugin-update.sh package/name /path/to/repository

# Clone the bare version of the provided repository to a temporary location.
git clone --bare $2 .dev/$1
# Get write control of all files, (mostly for sync issues and git permission errors (possibly a Windows only issue?)).
# Tell composer to update the plugin, which is already set to check the location checked out to.
ssh vagrant@192.168.33.10 -i ./../.vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
chmod -R u+w /var/www/vendor/$1
composer update $1
EOF
# Remove the temporary directory.
rm -rf .dev