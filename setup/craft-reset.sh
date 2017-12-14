# This script sets up craft, removing any existing databases and workspaces if necessary.
# This script can be run manually at any time from the GUEST.
# Vagrant also uses this script automatically as part of the initial provisioning process.

### Set up Craft 3

# Drop any existing craft database.
mysql -u root -prootpassword -e "DROP DATABASE IF EXISTS craft;"
# Create a database to use for craft.
mysql -u root -prootpassword -e "CREATE DATABASE craft;"
# Make sure everything is writable, so that it may be deleted
sudo chmod -R u+w /var/www/
# Delete all existing files
sudo rm -rf /var/www/{.,}*
# Create a Craft 3 project in the default web root (must be in an empty directory)
sudo composer create-project craftcms/craft /var/www/ -s beta
# Rename the Craft web root to become the normal web root
sudo mv /var/www/web/ /var/www/html/
# Set files within the web directory to be owned by the apache user
sudo chown -R apache:apache /var/www/
# Update configuration file
sudo sed -i 's/DB_PASSWORD=""/DB_PASSWORD="rootpassword"/' /var/www/.env
sudo sed -i 's/DB_DATABASE=""/DB_DATABASE="craft"/' /var/www/.env
# Keep in mind, craft setup, which can be done via the CLI, doesn't have command line options, and only makes the above adjustments anyway
# Run craft install via the CLI
sudo php /var/www/craft install --username="admin" --email="vagrant@localhost.localdomain" --password="craftdev" --siteName="Craft Dev" --siteUrl="http://192.168.33.10/" --language="en_us"
# New files have been added with the install script, get ownership of those, too.
sudo chown -R apache:apache /var/www/

### Clean up some residual craft things, to keep any workspace-level git repositories clean

# Readme and license files, to not conflict with any provided by a repository
sudo rm -rf /var/www/LICENSE.md
sudo rm -rf /var/www/README.md
# Example environment file, as that should more or less be either filled out, or just referenced from the regular '.env' file; they are the same, after all
sudo rm -rf /var/www/.env.example
# Example craft module
sudo rm -rf /var/www/modules/Module.php
# App config remove lines relating to example module
sudo sed -i "/my-module/d" /var/www/config/app.php

### Some really crazy stuff

# This will check to see if we can replace the installed FileMutex class from Yii 2 with our own custom edits.
# The MD5 will change if the underlying file is ever changed, which should prompt a re-edit of this file and
# the class that gets copied over. In real production environments it won't matter, but in the case of
# Vagrant virtualization, Yii's mutex handling causes issues for Craft.
mutexmd5="$(md5sum /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php)"
if [[ $mutexmd5 == "00a2c7f368a25ca533f925ae350732a9  /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php" ]]; then
	rm -f /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php
	cp /setup/FileMutex.php /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php
else
	echo "=================================================="
	echo "The file at /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php has been"
	echo "changed from the previous edition. Please edit manually with the"
	echo "changes present within /setup/FileMutex.php"
	echo "--------------------------------------------------"
	echo "The filesystem restrictions of the VirtualBox environment can tend to"
	echo "cause issues for Craft's job processing, because the processing uses"
	echo "file mutexes, which run Unix-related code, even though the shared"
	echo "folder system from VirtualBox honors and is restricted by Windows'"
	echo "limitations instead, causing PHP to crash."
	echo "=================================================="
fi
