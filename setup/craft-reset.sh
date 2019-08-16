#!/bin/bash
# This script sets up Craft, removing any existing database and workspace if necessary.
# This script can be run manually at any time from the GUEST.
# Pass `soft` as the first parameter if the Craft DB should be cleared and Craft reinstalled
# without removal/reset of any files.
# Vagrant also uses this script automatically as part of the initial provisioning process.

### Set up Craft 3

if [[ $1 != "soft" && $1 != "quiet" && $1 != "" ]]; then
	echo "Please specify either \"soft\" for a DB-only reset, or no parameter for a full reset."
	exit 1
fi

# Confirm this is what the user really wants to do
if [[ $1 != "quiet" ]]; then

	if [[ $1 != "soft" ]]; then
		echo "THIS WILL DESTROY ALL CRAFT DATA, INCLUDING ITS DATABASE AND FILES!"
	else
		echo "THIS WILL DESTROY THE CRAFT DATABASE, BUT LEAVE ALL OTHER FILES INTACT!"
	fi
	read -p "ARE YOU 200% SURE? (y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Goodbye, Craft!"
	else
		echo "Craft reset aborted, everything remains unchanged"
		exit 1
	fi
fi

# Hard (quiet) reset only
# Reset all files
if [[ $1 != "soft" ]]; then
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

	# This will check to see if we can replace the installed FileMutex class from Yii 2 with our own custom edits.
	# The MD5 will change if the underlying file is ever changed, which should prompt a re-edit of this file and
	# the class that gets copied over. In real production environments it won't matter, but in the case of
	# Vagrant virtualization, Yii's mutex handling causes issues for Craft.
	mutexmd5="$(md5sum /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php)"
	if [[ $mutexmd5 == "693b647756cd4970e798c520b233df35  /var/www/vendor/yiisoft/yii2/mutex/FileMutex.php" ]]; then
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
fi

# Hard and soft reset
# Database-specific setup
systemctl status mariadb
if [[ $? == 0 ]]; then
	# Drop and recreate the craft database (MySQL)
	mysql -u root -prootpassword -e "DROP DATABASE IF EXISTS craft;"
	mysql -u root -prootpassword -e "CREATE DATABASE craft;"
	# Make sure Craft is using the correct driver
	sudo sed -i 's/DB_DRIVER="pgsql"/DB_DRIVER="mysql"/' /var/www/.env
else
	# Drop and recreate the craft database (PostgreSQL)
	PGPASSWORD=rootpassword psql postgres root -c "DROP DATABASE IF EXISTS craft;"
	PGPASSWORD=rootpassword psql postgres root -c "CREATE DATABASE craft;"
	# Make sure Craft is using the correct driver
	sudo sed -i 's/DB_DRIVER="mysql"/DB_DRIVER="pgsql"/' /var/www/.env
fi
# Keep in mind, craft setup, which can be done via the CLI, doesn't have command line options, and only makes the above adjustments anyway
# Run craft install via the CLI
sudo php /var/www/craft install --username="admin" --email="vagrant@localhost.localdomain" --password="craftdev" --siteName="Craft Dev" --siteUrl="http://192.168.33.10/" --language="en_us"
systemctl status mariadb
if [[ $? == 0 ]]; then
	mysql -u root -prootpassword -e "UPDATE craft.userpreferences SET preferences = '{\"language\":\"en-US\",\"weekStartDay\":\"0\",\"enableDebugToolbarForSite\":true,\"enableDebugToolbarForCp\":true}';"
else
	PGPASSWORD=rootpassword psql craft root -c "UPDATE userpreferences SET preferences = '{\"language\":\"en-US\",\"weekStartDay\":\"0\",\"enableDebugToolbarForSite\":true,\"enableDebugToolbarForCp\":true}';"
fi
# New files have been added with the install script, get ownership of those, too
sudo chown -R apache:apache /var/www/

### Clean up some residual craft things, to keep any workspace-level git repositories clean

# Hard (quiet) reset only
if [[ $1 != "soft" ]]; then
	# Readme and license files, to not conflict with any provided by a repository
	sudo rm -rf /var/www/LICENSE.md
	sudo rm -rf /var/www/README.md
	# Example environment file, as that should more or less be either filled out, or just referenced from the regular '.env' file; they are the same, after all
	sudo rm -rf /var/www/.env.example
	# Remove the example craft module
	sudo rm -rf /var/www/modules/Module.php
	# Install the custom development modules
	sudo cp /setup/LoginHelper.php /var/www/modules/LoginHelper.php
	sudo cp /setup/EvalHelper.php /var/www/modules/EvalHelper.php
	# App config replace with development version, loading custom modules (and not the example one)
	sudo cp /setup/app.php /var/www/config/app.php
fi
