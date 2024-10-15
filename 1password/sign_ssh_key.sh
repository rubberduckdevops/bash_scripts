#! /usr/bin/env bash

if ! command -v op &> /dev/null
then
    echo "1Password CLI is not installed. Please install it first."
    exit 1
fi

if ! op account get &> /dev/null
then 
    echo "Please sign into 1 password CLI first 'eval(op signing)'"
    exit 1
fi

# read -p "Enter the name of 1Password CA Certificate:" item_name

item_name=LAB_USER_CA
temp_signing_key=$(mktemp)
op item get "$item_name" --field "private key" --reveal |  sed 's/\\n/\n/g' | sed 's/^"//; s/"$//'| sed '1d' > $temp_signing_key
signing_key=$(op item get "$item_name" --field "private key" | sed 's/\\n/\n/g' | sed 's/^"//; s/"$//')
chmod 600 "$temp_signing_key"

if [ -z "$signing_key" ]; then
    echo "Failed to get the signing key, try again."
    exit 1
fi

key_to_sign="$HOME/.ssh/id_ed25519.pub"

if [ ! -f "$key_to_sign" ]; then
    echo "SSH key not found at $key_to_sign"
    exit 1
fi



# signed_key=$(ssh-keygen -Y sign -f "$temp_signing_key" -n file "$key_to_sign")
signed_key=$(ssh-keygen -s "$temp_signing_key" -I "$USER" -n ducky -V +52w "$key_to_sign" )

if [ $? -ne 0 ]; then
    echo "Failed to sign key!"
    rm "$temp_signing_key"
    exit 1
fi

echo "Signed key saved to '$HOME/.ssh/id_ed25519-cert.pub'"

rm "$temp_signing_key"

echo "SSH Key signing completed successfully"
