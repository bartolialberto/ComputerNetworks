
function create_keypair_anonymous {
  if [[ $# != 1 ]]; then
    echo "create_keypair_anonymous - Usage:  \$1 = base filename for keypair"
    return 1
  fi
  openssl genpkey -algorithm RSA -out $1.privkey -pkeyopt rsa_keygen_bits:2048
  openssl rsa -in $1.privkey -pubout -out $1.pubkey
}

function encrypt_crypto_pub {
  if [[ $# != 2 ]]; then
    echo "encrypt_crypto_pub - Usage:  \$1 = public key \$2 = file to encrypt"
    return 1
  fi
  if [[ $1 != *.pubkey ]]; then
    echo "Error: The file with the public key does not end with '.pubkey'"
    return 1
  fi

  openssl pkeyutl -encrypt -pubin -inkey $1 -in $2 -out $2.enc_pub
}

function decrypt_crypto_pub {
  if [[ $# != 3 ]]; then
    echo "decrypt_crypto_pub - Usage:  \$1 = private key \$2 = file to decrypt \$3 = where to put the decrypted data"
    return 1
  fi
  if [[ $1 != *.privkey ]]; then
    echo "Error: The file with the private key does not end with '.privkey'"
    return 1
  fi
  if [[ $2 != *.enc_pub ]]; then
    echo "Error: The file to decrypt does not end with '.enc_pub'"
    return 1
  fi

  openssl pkeyutl -decrypt -inkey $1 -in $2 -out $3
}

function create_secret_key {
  if [[ $# != 1 ]]; then
    echo "create_secret_key - Usage:  \$1 = base filename for secret key"
    return 1
  fi
  openssl rand -out $1.secretkey 32
}

function encrypt_crypto_priv {
  if [[ $# != 2 ]]; then
    echo "encrypt_crypto_priv - Usage:  \$1 = secret key \$2 = file to encrypt"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi
  openssl enc -e -aes-256-cbc -in $2 -out $2.enc_secret -pass file:$1 -pbkdf2 -iter 100000
}

function decrypt_crypto_priv {
  if [[ $# != 3 ]]; then
    echo "decrypt_crypto_priv - Usage:  \$1 = secret key \$2 = file to decrypt \$3 = where to put the decrypted data"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi
  if [[ $2 != *.enc_secret ]]; then
    echo "Error: The file to decrypt does not end with '.enc_secret'"
    return 1
  fi

  openssl enc -d -aes-256-cbc -in $2 -out $3 -pass file:$1 -pbkdf2 -iter 100000
}

function hmac_create {
  if [[ $# != 2 ]]; then
    echo "hmac_create - Usage:  \$1 = secret key \$2 = file to hash"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi

  openssl dgst -sha256 -hmac $1 -binary -out $2.hmac $2
}

function hmac_verify {
  if [[ $# != 3 ]]; then
    echo "hmac_verify - Usage:  \$1 = secret key \$2 = file hashed \$3 = hmac"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi

  openssl dgst -sha256 -hmac $1 -binary -out tmp.hmac $2

  if cmp --silent tmp.hmac $3; then
        echo "HMAC is valid"
  else
        echo "HMAC is invalid"
  fi
  rm tmp.hmac

}

function sign {
  if [[ $# != 2 ]]; then
    echo "sign - Usage:  \$1 = private key \$2 = file to sign"
    return 1
  fi
  if [[ $1 != *.privkey ]]; then
    echo "Error: The file with the private key does not end with '.privkey'"
    return 1
  fi
  openssl dgst -sha256 -sign $1 -out /tmp/$2.sha256 $2
  openssl base64 -in /tmp/$2.sha256 -out $2.signature
  rm /tmp/$2.sha256
}

function verify {
  if [[ $# != 3 ]]; then
    echo "verify - Usage:  \$1 = public key \$2 = file to verify \$3 = signature"
    return 1
  fi
  if [[ $1 != *.pubkey ]]; then
    echo "Error: The file with the public key does not end with '.privkey'"
    return 1
  fi

  openssl base64 -d -in $3 -out /tmp/$2.sha256
  openssl dgst -sha256 -verify $1 -signature /tmp/$2.sha256 $2
  rm /tmp/$2.sha256

}

function create_keypair_subject {
  if [[ $# != 2 ]]; then
    echo "create_keypair_subject - Usage:  \$1 = subject short name \$2 = subject to be written in certificate"
    return 1
  fi
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $1.privkey -out $1-self.crt -subj "$2"
  openssl rsa -in $1.privkey -pubout -out $1.pubkey
}

function create_csr_subject {
  if [[ $# != 1 ]]; then
    echo "create_csr_subject - Usage:  \$1 = subject short name"
    return 1
  fi
  openssl x509 -x509toreq -in $1-self.crt -signkey $1.privkey -out $1.csr
}

function cert2publickey {
  if [[ $# != 2 ]]; then
    echo "cert2publickey - Usage:  \$1 = certificate \$2 = where to put the public key (without extension)"
    return 1
  fi
  if [[ $1 != *.crt ]]; then
    echo "Error: The file with the certificate does not end with '.crt'"
    return 1
  fi

  openssl x509 -in $1 -pubkey -noout > $2.pubkey

}

function issue_certificate {
  if [[ $# != 3 ]]; then
    echo "issue_certificate - Usage:  \$1 = csr \$2 = issuer self-signed certificate \$3 = issuer kpriv"
    return 1
  fi
  if [[ $1 != *.csr ]]; then
    echo "Error: The file with the certificate signing request does not end with '.csr'"
    return 1
  fi
  if [[ $2 != *.crt ]]; then
    echo "Error: The file with the CA self-signed certificate does not end with '.crt'"
    return 1
  fi
  if [[ $3 != *.privkey ]]; then
    echo "Error: The file with the CA private key does not end with '.privkey'"
    return 1
  fi
  base_name=${1%.csr}

  openssl x509 -req -in $1 -CA $2 -CAkey $3 -out $base_name.crt -days 365
}

function validate_certificate {
  if [[ $# != 2 ]]; then
    echo "validate_certificate - Usage:  \$1 = certificate \$2 = trustset"
    return 1
  fi
  if [[ $1 != *.crt ]]; then
    echo "Error: The file with the certificate does not end with '.crt'"
    return 1
  fi

  openssl verify -CAfile $2 $1
}


function send_TLS {
  if [[ $# != 3 ]]; then
    echo "send_TLS - Usage:  \$1 = secret key \$2 = message \$3 = where to put TLS message"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi

  openssl enc -aes-256-cbc -salt -in $2 -out tmp.msg -pass file:$1 -pbkdf2 -iter 100000
  openssl dgst -sha256 -hmac $1 -binary -out tmp.hmac tmp.msg
  cat tmp.msg tmp.hmac > $3
  rm tmp.msg tmp.hmac
}

function receive_TLS {
  if [[ $# != 3 ]]; then
    echo "send_TLS - Usage:  \$1 = secret key \$2 = TLS message \$3 = where to put message"
    return 1
  fi
  if [[ $1 != *.secretkey ]]; then
    echo "Error: The file with the secret key does not end with '.secretkey'"
    return 1
  fi

  head -c $(($(stat -c%s $2) - 32)) $2 > received_ciphertext.enc
  tail -c 32 $2 > received_hmac.bin

  openssl dgst -sha256 -hmac $1 -binary -out computed_hmac.bin received_ciphertext.enc

  if cmp --silent received_hmac.bin computed_hmac.bin; then
        echo "HMAC is valid"
  else
        echo "HMAC is invalid"
  fi
  openssl enc -aes-256-cbc -d -in received_ciphertext.enc -out $3 -pass file:$1 -pbkdf2 -iter 100000

  rm received_ciphertext.enc received_hmac.bin computed_hmac.bin
}