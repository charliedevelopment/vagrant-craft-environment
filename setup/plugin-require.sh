# This script requires a Composer package (Craft plugin) from an external repository.
# It should be run from the `workspace` directory of the HOST with the following options:
#
# plugin-require.sh package/name /path/to/repository

# Ignore the `/.dev` folder within the main workspace, if not already ignored (just in case).
grep -q -F '/.dev' .gitignore || echo '/.dev' >> .gitignore
# Clone the bare version of the provided repository to a temporary location.
git clone --bare $2 .dev/$1
# Configure Composer with some development presets.
# Install package from the temporary directory.
ssh vagrant@192.168.33.10 -i ./../.vagrant/machines/default/virtualbox/private_key << EOF
cd /var/www
composer config repositories.$1 git /var/www/.dev/$1
composer config minimum-stability dev
composer config prefer-stable true
composer require $1
EOF
# Remove the temporary directory.
rm -rf .dev
# Change the remote of the fake cloned repository to facilitate active development.
# This leaves composer's own remote for checking out when updating.
cd vendor/$1
git remote remove origin
git remote add origin $2
git fetch
git branch -u origin/master