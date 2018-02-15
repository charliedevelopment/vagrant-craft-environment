# This script generates a CA certificate with a default configuration.
# It should be run directly from its own folder on the HOST, though it is recommended to manually edit
# the configuration and change the location of the output files first, depending on your needs.
# It does not accept any options.

# Create an RSA key for local development.
# Make sure this is stored in a secure location, and do not lose it.
openssl genrsa -out ca-dev.key 4096

# Create a self-signed certificate with the above key.
# This certificate will be treated as a Certificate Authority, and will be installed as a root certificate on the local machine it is stored on.
# Any external parties connecting to the local development site will also need to trust this certificate.
# The process of trusting the certificate varies based on OS and browser.
openssl req -new -x509 -config ca-config.conf -sha256 -key ca-dev.key -out ca-dev.crt

# Create default db and serial files.
touch ca-db.txt
echo '01' > ca-serial.txt