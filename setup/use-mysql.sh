# This script switches from PostgreSQL to MySQL (Mariadb).
# This script can be run at any time from the GUEST.
# THIS WILL RESET THE CRAFT INSTALLATION AND DELETE ALL EXISTING DATA

### Make sure MariaDB isn't already active

systemctl status mariadb
if [[ $? == 0 ]]; then
	echo "MySQL is already the active database!"
	exit 1
fi

### Confirm this is what the user really wants to do

echo "THIS WILL DESTROY ALL CRAFT DATA, INCLUDING ITS DATABASE AND FILES. THE INSTANCE WILL THEN USE MYSQL!"
read -p "ARE YOU 200% SURE? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Tearing down PostgreSQL instance and setting up MySQL"
else
	echo "MySQL install aborted, everything remains unchanged"
	exit 1
fi

### Set up MySQL

# Stop the PostgreSQL service
sudo systemctl stop postgresql-9.6
sudo systemctl disable postgresql-9.6
# Start the MariaDB service
sudo systemctl enable mariadb
sudo systemctl start mariadb

### Reset the Craft install

/setup/craft-reset.sh quiet