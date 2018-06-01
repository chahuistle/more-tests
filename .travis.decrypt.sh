#!/usr/bin/env bash

# Usage: 
# $ .travis.decrypt.sh <rsa-file-destination>
#
# Takes an encrypted file, unencrypts it and splits it in two.
#
# This script assumes that said file, when unencrypted, contains two sections:
#
# 1. A script containing environment variables definitions (export VAR="value")
# 2. A private RSA key that Travis will use to perform passwordless SSH authentication. 
#    This file will be stored in the location given as a first positional argument
#    to this script.
#
# The two sections are separated by a "file separator", which is a 
# single line (see FILE_SEPARATOR variable down below).
#

# 1st argument: location on which we will store the RSA private key
RSA_PRIVATE_KEY_DESTINATION=$1

# location on which we will unencrypt the file
UNENCRYPTED_FILE_DESTINATION="/tmp/travis_deployment_key"
# file separator
FILE_SEPARATOR="###-#-#-#-quick-and-dirty-file-separator-THOU-SHALL-NOT-PASS-#-#-#-###"

## IMPORTANT: the variables starting with "encrypted_..." are different for every repository, make sure you edit this line
echo "Decrypting secret sauce..."
openssl aes-256-cbc -K $encrypted_3f7041caa607_key -iv $encrypted_3f7041caa607_iv -in travis_deployment_key.enc -out $UNENCRYPTED_FILE_DESTINATION -d
echo "Decryption return code: $?"

# find in which line is our file separator
FILE_SEPARATOR_LINE=`grep --line-number "$FILE_SEPARATOR" $UNENCRYPTED_FILE_DESTINATION | cut --fields 1 --delimiter=:`

# we know that the first part contains a script that will set all required environment variables, we just source it as-is
echo "Sourcing first $(( FILE_SEPARATOR_LINE - 1 )) lines..."
unset THE_EAGLE_HAS_LANDED
source <(head --lines $(( $FILE_SEPARATOR_LINE - 1 )) $UNENCRYPTED_FILE_DESTINATION)
# do some "sanity check"
if [ "$THE_EAGLE_HAS_LANDED" = "wizzard" ]; then
      # the second part of the unencrypted file contains a private key, output the last part of the unencrypted file into the desired destination
      tail --lines +$(( $FILE_SEPARATOR_LINE + 1 )) $UNENCRYPTED_FILE_DESTINATION > $RSA_PRIVATE_KEY_DESTINATION
      # make sure to change file permissions on this very special file
      chmod 600 $RSA_PRIVATE_KEY_DESTINATION 
else
      echo "[DUN GOOFED] I'm afraid I can't do that, Dave. Something went wrong with the deployment key file. Private key will not be extracted and deployment WILL fail."
      # better safe than sorry
      rm -f RSA_PRIVATE_KEY_DESTINATION
fi

# remove the unencrypted file
rm -f $UNENCRYPTED_FILE_DESTINATION