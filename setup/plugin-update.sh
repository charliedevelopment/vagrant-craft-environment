# This script force updates a Composer package (Craft plugin) from its underlying repository by copying the repository and updating from the same thing.
# It should be run from the vagrant environment folder of the HOST with the following options:
#
# plugin-update.sh package/name

# Copy the underlying repository to the temporary path.
mkdir workspace/.dev
cp -a workspace/vendor/$1/.git workspace/.dev/.git
# Start doing things on the box.
ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
# Update config to point to where we're temporarily storing the repository.
composer config repositories.$1 git /var/www/.dev/.git
# Make sure the files are writeable in the case of things getting deleted during the update.
chmod -R u+w /var/www/vendor/$1
# Update the plugin.
composer update $1
# Remove the plugin repository.
composer config repositories.$1 --unset
EOF
# Remove the temporary folder.
rm -rf workspace/.dev