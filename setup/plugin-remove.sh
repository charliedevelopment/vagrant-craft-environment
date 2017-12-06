# This script uninstalls Composer package (Craft plugin).
# It should be run from the `workspace` directory of the HOST with the following options:
#
# plugin-remove.sh package/name /path/to/repository

# Clone the bare version of the provided repository to a temporary location.
# To remove a package, Composer checks the package's source for updates first, so it needs to be cloned again (?!?!?).
git clone --bare $2 .dev/$1
# Get write control of all files, (mostly for sync issues and git permission errors (possibly a Windows only issue?)).
# Then remove the plugin.
ssh vagrant@192.168.33.10 -i ./../.vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
chmod -R u+w /var/www/vendor/$1
composer remove $1
EOF
# Remove the temporary directory.
rm -rf .dev