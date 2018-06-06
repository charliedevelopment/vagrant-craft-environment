# This script requires a Composer package (Craft plugin) from an external repository and then installs it.
# It should be run from the vagrant environment folder of the HOST with the following options:
#
# plugin-require.sh /path/to/repository

# Ensure the remote is valid before even trying.
git ls-remote $1 > /dev/null
if [[ $? -ne 0 ]]; then
    exit 1
fi
# Clone the provided repository to a temporary location.
git clone $1 workspace/.dev
# Retrieve the package name from the repository.
package_name="$(ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key "cd /var/www/.dev;composer config name")"
# Retrieve the plugin handle from the repository.
plugin_handle="$(ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key "cd /var/www/.dev;composer config extra.handle")"
# Start doing things on the box.
ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
# Update config to point to where we're temporarily storing the repository.
composer config repositories.$package_name git /var/www/.dev/.git
# Update config to get development repositories.
composer config minimum-stability dev
# Update config to force the most recent version.
composer config prefer-stable false
# Require the plugin, should pull from the temporary repository.
composer require $package_name
# Install the plugin with Craft.
./craft install/plugin $plugin_handle
# Remove the plugin repository.
composer config repositories.$package_name --unset
# Return the config to retrieving stable repositories if possible.
composer config prefer-stable true
EOF
# Remove the temporary folder.
rm -rf workspace/.dev
# Update the repository origin so that we can continue working from the copy in the `/vendor` folder.
cd workspace/vendor/$package_name
git remote remove origin
git remote add origin $1
git fetch
git branch -u origin/master