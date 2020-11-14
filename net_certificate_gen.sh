#!/usr/bin/env bash

printf "SET ENVIRONMENT\n\n"

export ca_dir=$HOME/CA
root_ca_config_path=$ca_dir/root-ca/root-ca.conf
sub_ca_config_path=$ca_dir/sub-ca/sub-ca.conf
server_config_path=$ca_dir/server/server_config.conf
client_config_path=$ca_dir/client/client_config.conf
pass=$ca_dir/pass/pass.aes256

printf "CREATED CLIENT FOLDER\n\n"

mkdir -p $ca_dir/client/{certs,private,csr}


printf "CREATED SERIAL\n\n"

openssl rand -hex 16 > $ca_dir/ca-chain/ca-chain.srl

cat << EOF > $server_config_path
basicConstraints        = critical, CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement 
extendedKeyUsage        = critical, serverAuth
subjectAltName          = @alt_names

[ alt_names ]
# Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.1 = localhost 
IP.1 = 127.0.0.1

[ req ]
# Options for the req tool, man req.
default_bits   = 2048
distinguished_name  = req_distinguished_name
string_mask   = utf8only
default_md   =  sha256

[ req_distinguished_name ]
countryName                     = BR
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = ElectricStone Ltd
organizationalUnitName          = FakeProvider
commonName                      = ElectricStone SUB CA
emailAddress                    = Email Address
countryName_default  = BR
stateOrProvinceName_default = Brazil
0.organizationName_default = ElectricStone Ltd
organizationalUnitName_default = FakeProvider
commonName_default = localhost
EOF

cat << EOF > $client_config_path
basicConstraints        = critical, CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage        = critical, clientAuth
subjectAltName          = @alt_names

[ req ]
# Options for the req tool, man req.
default_bits   = 2048
distinguished_name  = req_distinguished_name
string_mask   = utf8only
default_md   =  sha256

[ req_distinguished_name ]
countryName                     = BR
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = ElectricStone Ltd
organizationalUnitName          = eCommerce
commonName                      = ElectricStone SUB CA
emailAddress                    = Email Address
countryName_default  = BR
stateOrProvinceName_default = Brazil
0.organizationName_default = ElectricStone Ltd
organizationalUnitName_default = eCommerce
commonName_default = localhost

[ alt_names ]
# Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.1 = localhost 
IP.1 = 127.0.0.1
EOF

printf "CREATING SERVER PRIVATE KEY...\n\n"

openssl genrsa -out $ca_dir/server/private/netwebapp.key 2048

printf "CREATING CLIENT PRIVATE KEY...\n\n"

openssl genrsa -out $ca_dir/client/private/netwebappclient.key 2048

printf "CREATING A SERVER SIGNING REQUEST...\n\n"

openssl req -config $server_config_path -passin file:$pass -key $ca_dir/server/private/netwebapp.key \
-new -sha256 -out $ca_dir/server/csr/netwebapp.csr

printf "CREATING A CLIENT SIGNING REQUEST...\n\n"

openssl req -config $client_config_path -passin file:$pass -key $ca_dir/client/private/netwebappclient.key \
-new -sha256 -out $ca_dir/client/csr/netwebappclient.csr

printf "CREATING THE SERVER CERTIFICATE...\n\n"

openssl x509 -req -in $ca_dir/server/csr/netwebapp.csr -passin file:$pass \
-CA $ca_dir/ca-chain/ca-chain.crt \
-CAkey $ca_dir/sub-ca/private/sub-ca.key \
-CAserial $ca_dir/ca-chain/ca-chain.srl \
-out $ca_dir/server/certs/netwebapp.crt -days 365 -sha256 -extfile $server_config_path

printf "CREATING THE CLIENT CERTFICATE...\n\n"

openssl x509 -req -in $ca_dir/client/csr/netwebappclient.csr -passin file:$pass \
-CA $ca_dir/ca-chain/ca-chain.crt \
-CAkey $ca_dir/sub-ca/private/sub-ca.key \
-CAserial $ca_dir/ca-chain/ca-chain.srl \
-out $ca_dir/client/certs/netwebappclient.crt -days 365 -sha256 -extfile $client_config_path

# Testing the server certificate

sudo openssl s_server -accept 443 -www -key $ca_dir/server/private/netwebapp.key \
-CAfile $ca_dir/sub-ca/certs/sub-ca.crt \
-cert $ca_dir/server/certs/netwebapp.crt

# Testing the client certificate

openssl s_client -connect localhost:443 -servername localhost \
-CAfile $ca_dir/root-ca/certs/ca.crt \
-showcerts

# openssl pkcs12 -export -out $ca_dir/server/certs/netwebapp.pfx \
# -in $ca_dir/server/certs/netwebapp.crt \
# -inkey $ca_dir/server/private/netwebapp.key
# -CAfile $ca_dir/root-ca/certs/ca.crt \
# -certfile $ca_dir/sub-ca/certs/sub-ca.crt \

# openssl pkcs12 -export -in $ca_dir/server/certs/netwebapp.crt \
# -inkey $ca_dir/server/private/netwebapp.key \
# -certfile $ca_dir/sub-ca/certs/sub-ca.crt \
# -CAfile $ca_dir/root-ca/certs/ca.crt -chain -out $ca_dir/server/certs/netwebapp.pfx 

# cat $ca_dir/server/certs/server.crt $ca_dir/ca-chain/ca-chain.crt | openssl pkcs12 \
# -export -out $ca_dir/server/certs/netwebapp.pfx -password file:$pass