# This script switches from MySQL (Mariadb) to PostgreSQL.
# This script can be run at any time from the GUEST.
# THIS WILL RESET THE CRAFT INSTALLATION AND DELETE ALL EXISTING DATA

### Make sure PostgreSQL isn't already active

systemctl status postgresql
if [[ $? == 0 ]]; then
	echo "PostgreSQL is already the active database!"
	exit 1
fi

### Confirm this is what the user really wants to do

echo "THIS WILL DESTROY ALL CRAFT DATA AND RESET THE INSTANCE TO USE POSTGRESQL!"
read -p "ARE YOU 200% SURE? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "Tearing down MySQL instance and setting up PostgreSQL"
else
	echo "PostgreSQL install aborted, everything remains unchanged"
	exit 1
fi

### Set up PosgreSQL

# Stop the MariaDB service
sudo systemctl stop mariadb
sudo systemctl disable mariadb
# Only run install/initial setup if PostgreSQL isn't currently installed
yum list installed postgresql-server
if [[ $? == 1 ]]; then
	sudo yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
	# Install PostgreSQL
	sudo yum install -y postgresql96
	sudo yum install -y postgresql96-server
	# Initialize the PostgreSQL database
	sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
	# Start the PostgreSQL service
	sudo systemctl enable postgresql-9.6
	sudo systemctl start postgresql-9.6
	# Create a root superuser for the PostgreSQL database, to match the MySQL configuration
	sudo -u postgres psql -c "CREATE USER root WITH PASSWORD 'rootpassword';"
	sudo -u postgres psql -c "ALTER USER root WITH SUPERUSER;"
	# Install PHP PostgreSQL extension
	sudo yum -y install php-pgsql
	# Copy PostgreSQL configuration
	sudo mv /var/www/pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf
	# Restart the PostgreSQL service
	sudo systemctl restart postgresql-9.6
else
	# Start the PostgreSQL service
	sudo systemctl enable postgresql-9.6
	sudo systemctl start postgresql-9.6
fi

### Reset the Craft install

/setup/craft_reset.sh