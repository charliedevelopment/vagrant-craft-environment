# This script installs a certificate for a development site.
# It should be run from the vagrant environment folder of the HOST with the following options:
#
# install-cert.sh domain.name /path/to/key.key /path/to/cert.crt

# Copy the cert and key to an accessible location.
cp $2 workspace/localhost.key
cp $3 workspace/localhost.crt
# Start doing things on the box.
ssh vagrant@192.168.33.10 -i .vagrant/machines/default/virtualbox/private_key << EOF
# Make sure the appropriate apache module is installed.
sudo yum install -y mod_ssl
# Remove existing temporary key/cert.
sudo rm /etc/pki/tls/certs/localhost.crt
sudo rm /etc/pki/tls/private/localhost.key
# Move domain key and cert over.
sudo mv /var/www/localhost.crt /etc/pki/tls/certs/localhost.crt
sudo mv /var/www/localhost.key /etc/pki/tls/private/localhost.key
# Restart Apache.
sudo systemctl restart httpd
EOF