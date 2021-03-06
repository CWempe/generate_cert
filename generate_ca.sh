#!/bin/bash

# http://code.rogerhub.com/infrastructure/474/signing-your-own-wildcard-sslhttps-certificates/

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Ein " um das Syntaxhighlighting wieder zu korrigieren


CAname="CA"
if [ ! -d "$WORKDIR/$CAname" ]
    then
        mkdir $WORKDIR/$CAname
fi

CAkey="$WORKDIR/$CAname/$CAname.key"
CApem="$WORKDIR/$CAname/$CAname.pem"
CAtxt="$WORKDIR/$CAname/$CAname.txt"
CAsrl="$WORKDIR/$CAname/$CAname.srl"

ISSUERFILE="$WORKDIR/issuer.conf"

if [ -f "$ISSUERFILE" ]
    then
        source "$ISSUERFILE"
    else
        echo "Using $ISSUERFILE.example"
        source "$ISSUERFILE.example"
fi

# Generate Private Key
if [ -f "$CAkey" ]
    then
        echo "$CAkey already exists. Skip generation."
    else
        echo "Generate $CAkey ..."
        openssl genrsa -out "$CAkey" 4096
fi

# Generate Public Key
if [ -s "$CApem" ]
    then
        echo "$CApem already exists. Skip generation."
    else
        echo "Generate $CApem ..."
        rm -f "$CApem"
        openssl req -x509 -sha256 -new -nodes -key "$CAkey" -days 9999 -out "$CApem" -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN"
fi

openssl x509 -in "$CApem" -text -noout > "$CApem.txt"

# fix file permissions to make it secure
chmod 600 "$WORKDIR/$CAname/"*
