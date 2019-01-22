# This script runs on the GUEST the first time provisioning a virtual box.
# Do not run this script manually, Vagrant does this for you.

### Initial OS configuration/Setup

# Ensure the provision doesn't accidentally rerun over an already-provisioned system
if [ -f /var/www/composer.json ]; then
	echo "=================================================="
	echo "Attempted to run provisioning on a VM with an already-provisioned workspace."
	echo "This is generally a very bad thing, please check appropriate configurations to ensure your VMs actually exist."
	echo "=================================================="
	exit 1
fi

# Create the apache user with a specific, predefined user and group id
# This is used for the shared folder that holds the craft install, since it is mounted to the default web server folder.
sudo groupadd -g 48 apache
sudo useradd -u 48 -g 48 -d /usr/share/httpd -s /sbin/nologin apache
# Add vagrant to that group, so the default user can ssh in and make changes to shared files easily.
sudo usermod -a -G apache vagrant

# Disable SELinux
# Especially since this is just a temporary development environment, but configuring SELinux to work well with all the services would take an unnecessary amount of time.
sudo setenforce Permissive
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Set the executable bit on the convenience scripts, so they can be run without having to fix this manually.
chmod u+x /setup/*.sh

### Install packages

# Install Apache
sudo yum -y install httpd
# Install perl, as a prerequisite for mysql (mariadb)
sudo yum -y install perl
# Install net-tools, as a prerequisite for mysql (mariadb)
sudo yum -y install net-tools
# Install mariadb (mysql)
sudo yum -y install mariadb-server
# Install git, to install Craft, and automate updates/deployment
sudo yum -y install git
# Install zip/unzip for archive management
sudo yum -y install zip
sudo yum -y install unzip
# Install PHP 7 from the unofficial remi repository, allow additional modules to be installed from this repository, too (Official for CentOS/RHEL only goes up to PHP 5.6)
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71
sudo yum -y update
# Install PHP MySQL extension, for general use
sudo yum -y install php-mysql
# Install PHP ImageMagick extension, for craft
sudo yum -y install php-imagick
# Install PHP command line tools, for composer
sudo yum -y install php-cli
# Install PHP zip extension, for composer (and probably general use)
sudo yum -y install php-zip
# Install PHP dom extension, for craft
sudo yum -y install php-dom
# Install PHP mbstring extension, for craft
sudo yum -y install php-mbstring
# Install PHP internationalization extension, for craft
sudo yum -y install php-intl
# Install Apache PHP module
sudo yum -y install mod_php

### Set up MySQL

# Start the service
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
# Set the password for the root account
sudo /usr/bin/mysqladmin -u root password 'rootpassword'
# Give the root user full access to everything
mysql -u root -prootpassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'rootpassword' WITH GRANT OPTION; FLUSH PRIVILEGES;"
# Remove the anonymous users
mysql -u root -prootpassword -e "DROP USER ''@'localhost';"
mysql -u root -prootpassword -e "DROP USER ''@'$(hostname)';"
# Remove the test database
mysql -u root -prootpassword -e "DROP DATABASE test;"

### Set up Apache

# Copy preset Apache configuration
sudo rm -rf /etc/httpd/conf/httpd.conf
sudo cp /setup/httpd.conf /etc/httpd/conf/httpd.conf

### Set up PHP

# Copy preset PHP configuration
sudo rm -rf /etc/php.ini
sudo cp /setup/php.ini /etc/php.ini

### Set up Composer

# Download and unpack Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
# Move composer to bin folder, so it can be accessed globally
sudo mv composer.phar /usr/bin/composer