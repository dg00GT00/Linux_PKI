#!/usr/bin/env bash

: <<'END_OF_DOCS'
################## Creating a Public Key Infrastructure ##################

This is for development only. 
The Root CA would normally be offline and never connected to the network. 
The Intermediate CA can be online but often not on the samesystem as other servers

END_OF_DOCS

export ca_dir=$HOME/CA

printf "CREATED PKI DIRECTORIES\n\n"

mkdir -p $ca_dir/{root-ca,sub-ca,server}/{private,certs,newcerts,crl,csr} $ca_dir/ca-chain $ca_dir/pass

export root_ca_config_path=$ca_dir/root-ca/root-ca.conf
export sub_ca_config_path=$ca_dir/sub-ca/sub-ca.conf

pass=$ca_dir/pass/pass.aes256

printf "ENTER A PASSWORD FOR PRIVATE KEY GENERATION\n\n"

echo -e $1 | openssl enc -aes256 -pbkdf2 -salt -out $ca_dir/pass/pass.aes256    

cat << EOF > $root_ca_config_path
[ ca ]
#$ca_dir/root-ca/root-ca.conf
#see man ca
default_ca    = CA_default

[ CA_default ]
dir     = $ca_dir/root-ca
certs     =  \$dir/certs
crl_dir    = \$dir/crl
new_certs_dir   = \$dir/newcerts
database   = \$dir/index
serial    = \$dir/serial
RANDFILE   = \$dir/private/.rand

private_key   = \$dir/private/ca.key
certificate   = \$dir/certs/ca.crt

crlnumber   = \$dir/crlnumber
crl    =  \$dir/crl/ca.crl
crl_extensions   = crl_ext
default_crl_days    = 30

default_md   = sha256

name_opt   = ca_default
cert_opt   = ca_default
default_days   = 365
preserve   = no
policy    = policy_strict

[ crl_ext ]
authorityKeyIdentifier = keyid:always,issuer:always

[ policy_strict ]
countryName   = match
stateOrProvinceName  =  supplied
organizationName  = match
organizationalUnitName  =  optional
commonName   =  supplied
emailAddress   =  optional

[ req ]
# Options for the req tool, man req.
default_bits   = 2048
distinguished_name  = req_distinguished_name
string_mask   = utf8only
default_md   =  sha256
# Extension to add when the -x509 option is used.
x509_extensions   = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = ElectricStone Root CA
emailAddress                    = Email Address
countryName_default  = BR
stateOrProvinceName_default = Brazil
0.organizationName_default = ElectricStone Ltd

[ v3_ca ]
# Extensions to apply when createing root ca
# Extensions for a typical CA, man x509v3_config
subjectKeyIdentifier  = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints  = critical, CA:true
keyUsage   =  critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions to apply when creating intermediate or sub-ca
# Extensions for a typical intermediate CA, same man as above
subjectKeyIdentifier  = hash
authorityKeyIdentifier  = keyid:always,issuer
#pathlen:0 ensures no more sub-ca can be created below an intermediate
basicConstraints  = critical, CA:true, pathlen:0
keyUsage   = critical, digitalSignature, cRLSign, keyCertSign
EOF

cat << EOF > $sub_ca_config_path
[ ca ]
#/root/ca/sub-ca/sub-ca.conf
#see man ca
default_ca    = CA_default

[ CA_default ]
dir     = $ca_dir/sub-ca
certs     =  \$dir/certs
crl_dir    = \$dir/crl
new_certs_dir   = \$dir/newcerts
database   = \$dir/index
serial    = \$dir/serial
RANDFILE   = \$dir/private/.rand

private_key   = \$dir/private/sub-ca.key
certificate   = \$dir/certs/sub-ca.crt

crlnumber   = \$dir/crlnumber
crl    =  \$dir/crl/sub-ca.crl
crl_extensions   = crl_ext
default_crl_days    = 30

default_md   = sha256

name_opt   = ca_default
cert_opt   = ca_default
default_days   = 365
preserve   = no
policy    = policy_strict

[ crl_ext ]
authorityKeyIdentifier = keyid:always,issuer:always

[ policy_strict ]
countryName   = match
stateOrProvinceName  =  supplied
organizationName  = match
organizationalUnitName  =  optional
commonName   =  supplied
emailAddress   =  optional

[ req ]
# Options for the req tool, man req.
default_bits   = 2048
distinguished_name  = req_distinguished_name
string_mask   = utf8only
default_md   =  sha256
# Extension to add when the -x509 option is used.
x509_extensions   = v3_intermediate_ca

[ req_distinguished_name ]
countryName                     = BR
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = ElectricStone Ltd
organizationalUnitName          = Organizational Unit Name
commonName                      = ElectricStone SUB CA
emailAddress                    = Email Address
countryName_default  = BR
stateOrProvinceName_default = Brazil
0.organizationName_default = ElectricStone Ltd

[ v3_intermediate_ca ]
# Extensions to apply when creating intermediate or sub-ca
# Extensions for a typical intermediate CA, same man as above
subjectKeyIdentifier  = hash
authorityKeyIdentifier  = keyid:always,issuer
#pathlen:0 ensures no more sub-ca can be created below an intermediate
basicConstraints  = critical, CA:true, pathlen:0
keyUsage   = critical, digitalSignature, cRLSign, keyCertSign
crlDistributionPoints = URI:http://localhost:5002/crl/server.crl # SPECIFIC TO EACH DOMAIN

[ server_cert ]
# Extensions for server certificates
basicConstraints  = CA:FALSE
nsCertType   = server
nsComment   =  "OpenSSL Generated Server Certificate"
subjectKeyIdentifier  = hash
authorityKeyIdentifier  = keyid,issuer:always
keyUsage   =  critical, digitalSignature, keyEncipherment
extendedKeyUsage  = serverAuth
subjectAltName = @alt_names

[ alt_names ]
# Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.1 = localhost 
IP.1 = 127.0.0.1
EOF

printf "TURNING THE PRIVATE DIRECTORIES PRIVATE...\n"

chmod -v 700 $ca_dir/{root-ca,sub-ca,server}/private

printf "CREATED THE INDEX FILE\n\n"

touch $ca_dir/{root-ca,sub-ca}/index

printf "CREATED SERIAL NUMBERS\n\n"

openssl rand -hex 16 > $ca_dir/root-ca/serial
openssl rand -hex 16 > $ca_dir/sub-ca/serial

printf "CREATED CRL NUMBERS\n\n"

openssl rand -hex 16 > $ca_dir/root-ca/crlnumber
openssl rand -hex 16 > $ca_dir/sub-ca/crlnumber

printf "CREATING THE CA PRIVATE KEY - PASS-PHRASE NEEDED...\n\n"

openssl genrsa -aes256 -passout file:$pass -out $ca_dir/root-ca/private/ca.key 4096 

printf "\n\nCREATING THE SUB-CA PRIVATE KEY - PASS-PHRASE NEEDED...\n\n"

openssl genrsa -aes256 -passout file:$pass -out $ca_dir/sub-ca/private/sub-ca.key 4096

printf "\n\nCREATING THE SERVER PRIVATE KEY...\n\n"

openssl genrsa -out $ca_dir/server/private/server.key 2048

printf "\n\nCREATING THE CA CERTIFICATE... (WARNING: Fullfil the 'CommonName' field even though it already have a default value)\n\n"

openssl req -config $root_ca_config_path -passin file:$pass \
-key $ca_dir/root-ca/private/ca.key -new -x509 -days 7500 \
-sha256 -extensions v3_ca -out $ca_dir/root-ca/certs/ca.crt

printf "\n\nCREATING A SUB-CA SIGNING REQUEST... (WARNING: Fullfil the 'CommonName' field even though it already have a default value) \n\n"

openssl req -config $sub_ca_config_path -passin file:$pass -new -key $ca_dir/sub-ca/private/sub-ca.key -sha256 -out $ca_dir/sub-ca/csr/sub-ca.csr

printf "\n\nCREATING A SUB-CA CERTIFICATE...\n\n"

openssl ca -config $root_ca_config_path -passin file:$pass -extensions v3_intermediate_ca -days 3650 -notext -in $ca_dir/sub-ca/csr/sub-ca.csr \
-out $ca_dir/sub-ca/certs/sub-ca.crt

# Server certificates

printf "\n\nCREATING SERVER SIGNING REQUEST...(WARNING: Common Name field is required) \n\n"

openssl req -passin file:$pass -key $ca_dir/server/private/server.key -new -sha256 -out $ca_dir/server/csr/server.csr

printf "\n\nCREATING SERVER CERTIFICATE SIGNED BY SUB-CA...\n\n"

openssl ca -passin file:$pass -config $sub_ca_config_path -extensions server_cert -days 365 -notext -in $ca_dir/server/csr/server.csr \
-out $ca_dir/server/certs/server.crt

# Chained certificates

printf "\n\nCREATING A CERTIFICATE CHAIN...\n\n"

cat $ca_dir/sub-ca/certs/sub-ca.crt $ca_dir/root-ca/certs/ca.crt > $ca_dir/ca-chain/ca-chain.crt

printf "\n\nCREATING SERVER CRL...\n\n"

openssl ca -passin file:$pass -config $sub_ca_config_path -gencrl -out $ca_dir/server/crl/server.crl -crlexts crl_ext

# Testing the server certificate
sudo openssl s_server -accept 443 -www -key $ca_dir/server/private/server.key -cert $ca_dir/server/certs/server.crt -CAfile $ca_dir/sub-ca/certs/sub-ca.crt