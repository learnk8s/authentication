#!/bin/bash

#------------------------------------------------------------------------------#
# Set up an OpenLDAP server.
#
# To create an OpenLDAP server on a GCP compute instance named 'ldap', proceed
# as follows.
#
# Upload script to instance with:
#   gcloud compute scp setup-ldap-server.sh root@ldap:setup-ldap-server.sh
#
# Log in to the instance:
#   gcloud compute ssh root@ldap
#
# Run the script on the instance:
#   ./setup-ldap-server.sh
#
# Note: running the script with 'gcloud compute ssh --command' doesn't work
# because 'apt-get install slapd' includes a prompt for the LDAP admin password.
#------------------------------------------------------------------------------#

set -e

#------------------------------------------------------------------------------#
# Install OpenLDAP and client tools
#
# Note: when prompted for the LDAP admin password, choose 'password'. This
# value is hardcoded in the subsequent commands of this script.
#------------------------------------------------------------------------------#

apt-get update
apt-get install -y slapd ldap-utils

#------------------------------------------------------------------------------#
# Change the suffix of the main database from the default name, which includes
# the GCP project name, to 'dc=mycompany,dc=com'.
#------------------------------------------------------------------------------#

# Export existing database entries
slapcat >data.ldif

# Kill the running OpenLDAP server
pkill -9 slapd

# Delete the existing database file
# HARDCODED: value in /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif
rm -f /var/lib/ldap/*

# Start up the OpenLDAP server again
# HARDCODED: startup command is in /var/run/slapd/slapd.args; this file is
# specified in /etc/ldap/slapd.d/cn\=config.ldif
slapd -h "ldap:/// ldapi:///" -g openldap -u openldap -F /etc/ldap/slapd.d

# Update suffix in database configuration
cat <<EOF >update.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=mycompany,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=mycompany,dc=com
EOF
ldapmodify -Y EXTERNAL -H ldapi:// -f update.ldif

# Update suffix in exported data 
old_suffix=$(sed -n 's/^dn:\s*\(.*\).*/\1/p;q' data.ldif)
sed -i "s/$old_suffix/dc=mycompany,dc=com/g" data.ldif
sed -i 's/^o:.*/o: mycompany.com/' data.ldif
sed -i 's/^dc:.*/dc: mycompany/' data.ldif

# Recreate data with the new suffix
slapadd <data.ldif

#------------------------------------------------------------------------------#
# Create an initial user
#------------------------------------------------------------------------------#

cat <<EOF >user.ldif
dn: cn=weibeld,dc=mycompany,dc=com
objectClass: top
objectClass: inetOrgPerson
cn: weibeld
givenName: Daniel
sn: Weibel
userPassword: password
mail: danielmweibel@gmail.com
ou: dev-team-1
EOF
ldapadd -x -D 'cn=admin,dc=mycompany,dc=com' -w password -f user.ldif

# Example query for the created user
ldapsearch -x -D 'cn=admin,dc=mycompany,dc=com' -w password -b 'dc=mycompany,dc=com' '(&(objectClass=person)(cn=weibeld)(userPassword=password))'

#------------------------------------------------------------------------------#
# Clean up
#------------------------------------------------------------------------------#

rm -f data.ldif update.ldif user.ldif
