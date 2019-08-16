#!/bin/bash
# This script generates a certificate for a development site, signing it based on a provided
# CA certificate configuration.
# It should be run directly from its own folder on the HOST with the following options:
#
# generate-cert.sh domain.name /path/to/ca.conf

# Make note of the domain that a certificate is being generated for, and
# the configuration being used.
echo Generating certificate for $1
echo And signing it according to the configuration stored at $2

# Create a key for the development site.
openssl genrsa -out site-dev.key 4096

# Copy the base configuration with the updated domains.
sed -e "s/localhost.localdomain/$1/" site-config.conf > temp-config.conf

# Create a Certificate Signing Request for the development site.
# This certificate will be signed by the CA certificate generated above, and installed for use on the local development site.
openssl req -new -sha256 -nodes -key site-dev.key -out site-dev.csr -config temp-config.conf

# Remove the modified temporary configuration.
rm -rf temp-config.conf

# Issue a certificate for the CSR and sign it with the CA key.
openssl ca -batch -config $2 -policy signing_policy -extensions signing_req -out site-dev.crt -infiles site-dev.csr
