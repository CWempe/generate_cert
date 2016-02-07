#!/bin/bash

# http://code.rogerhub.com/infrastructure/474/signing-your-own-wildcard-sslhttps-certificates/

echo  -e "Please input hostname (without subdomain): "
read SERVER

echo  -e "Please input subdomain: "
read SUBDOMAIN


WORKDIR="."

# File containing dynamic DNS-Entries like 'example.dyndns.org' or 'example.myqnapcloud.com'
DYNDNSFILE="$WORKDIR/dyndns.txt"

CAname="CA"
CAkey="$WORKDIR/$CAname/$CAname.key"
CApem="$WORKDIR/$CAname/$CAname.pem"
CAtxt="$WORKDIR/$CAname/$CAname.txt"
CAsrl="$WORKDIR/$CAname/$CAname.srl"

if [ ! -d "$WORKDIR/$SERVER" ]
    then
        mkdir $WORKDIR/$SERVER
fi

CERTcfn="$WORKDIR/$SERVER/$SERVER.cfn"
CERTkey="$WORKDIR/$SERVER/$SERVER.key"
CERTcsr="$WORKDIR/$SERVER/$SERVER.csr"
CERTcrt="$WORKDIR/$SERVER/$SERVER.crt"
CERTpem="$WORKDIR/$SERVER/$SERVER.pem"
CERTtxt="$WORKDIR/$SERVER/$SERVER.txt"
CERTp12="$WORKDIR/$SERVER/$SERVER.p12" 

CHAINpem="$WORKDIR/$SERVER/chain.pem"


ISSUERFILE="$WORKDIR/issuer.conf"

if [ -f "$ISSUERFILE" ]
    then
        source "$ISSUERFILE"
    else
        C=""
        ST=""
        L=""
        O=""
        OU=""
fi


# generate openssl-config with wildcards
if [ -f "$CERTcfn" ]
    then
        echo "$CERTcfn already exists. Skip generation."
    else
        echo "Generate $CERTcfn ..."
        cp openssl_custom.cnf "$CERTcfn"
        echo "DNS.1 = $SERVER"                         >> "$CERTcfn"
        echo "DNS.2 = $SERVER.$SUBDOMAIN"              >> "$CERTcfn"

        if [ -f "$DYNDNSFILE" ]
            then
                COUNTER=3
                while read -r DYNDNS || [[ -n "$DYNDNS" ]]; do
                    echo "DNS.$COUNTER = $DYNDNS"              >> "$CERTcfn"
                    COUNTER=$((COUNTER + 1))
                done < "$DYNDNSFILE"
                echo ""                                        >> "$CERTcfn"
            else
                echo "$DYNDNSFILE does not exist."
        fi
fi





# Generate Private Key
if [ -f "$CERTkey" ]
    then
        echo "$CERTkey already exists. Skip generation."
    else
        echo "Generate $CERTkey ..."
        openssl genrsa -out "$CERTkey" 2048
fi

# Generate Certificate Signing Request
if [ -f "$CERTcsr" ]
    then
        echo "$CERTcsr already exists. Skip generation."
    else
        echo "Generate $CERTcsr ..."
        openssl req -sha256 -new -key "$CERTkey" -out "$CERTcsr" -config "$CERTcfn" -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$SERVER"
fi


openssl req -in "$CERTcsr" -text -noout > "$CERTcsr.txt"



# Sign the CSR with the CA
openssl x509 -req -sha256 -days 9999 -in "$CERTcsr" -CA "$CApem" -CAkey "$CAkey" -CAserial "$CAsrl" -extensions v3_req -out "$CERTcrt" -extfile "$CERTcfn"

# Generate certificate with private key in PEM-format
cat "$CERTcrt" "$CERTkey" > "$CERTpem"

openssl x509 -in "$CERTcrt" -text -noout > "$CERTcrt.txt"

# Generate certificate chain in PEM-format
cat "$CApem" "$CERTcrt" > "$CHAINpem"
# Generate PKCS#12 container with ca.crt, server.crt and server.key
openssl pkcs12 -export -inkey "$CERTkey" -in "$CHAINpem" -out "$CERTp12"
openssl pkcs12 -in "$CERTp12" -nodes > "$CERTp12.txt"