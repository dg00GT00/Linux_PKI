#!/usr/bin/env bash

ca_dir=$HOME/CA
root_ca_config_path=$ca_dir/root-ca/root-ca.conf
sub_ca_config_path=$ca_dir/sub-ca/sub-ca.conf
pass=$ca_dir/pass/pass.aes256

openssl genrsa -out $ca_dir/server/private/netwebapp.key 2048

openssl req -passin file:$pass -key $ca_dir/server/private/netwebapp.key -new -sha256 -out $ca_dir/server/csr/netwebapp.csr

openssl ca -passin file:$pass -config $sub_ca_config_path -extensions server_cert -days 365 -notext -in $ca_dir/server/csr/netwebapp.csr \
-out $ca_dir/server/certs/netwebapp.crt

openssl ca -passin file:$pass -config $sub_ca_config_path -gencrl -out $ca_dir/server/crl/netwebapp.crl -crlexts crl_ext

# openssl crl2pkcs7 -in $ca_dir/server/crl/netwebapp.crl \
# -certfile $ca_dir/server/certs/netwebapp.crt \
# -out $ca_dir/server/certs/netwebapp.p7b \
# -certfile $ca_dir/sub-ca/certs/sub-ca.crt \
# -certfile $ca_dir/root-ca/certs/ca.crt \

# openssl pkcs12 -export -out $ca_dir/server/certs/netwebapp.pfx \
# -in $ca_dir/server/certs/netwebapp.crt \
# -inkey $ca_dir/server/private/netwebapp.key
# -CAfile $ca_dir/root-ca/certs/ca.crt \
# -certfile $ca_dir/sub-ca/certs/sub-ca.crt \

# openssl pkcs12 -export -in $ca_dir/server/certs/netwebapp.crt \
# -inkey $ca_dir/server/private/netwebapp.key \
# -certfile $ca_dir/sub-ca/certs/sub-ca.crt \
# -CAfile $ca_dir/root-ca/certs/ca.crt -chain -out $ca_dir/server/certs/netwebapp.pfx 

cat $ca_dir/server/certs/server.crt $ca_dir/ca-chain/ca-chain.crt | openssl pkcs12 \
-export -out $ca_dir/server/certs/netwebapp.pfx -password file:$pass