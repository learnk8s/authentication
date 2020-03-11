#!/bin/bash
#
# Install and configure an OpenLDAP.
#
# 1. Upload script to the instance with:
#
#   gcloud compute scp ldap-setup.sh root@ldap:ldap-setup.sh
#
# 2. Log in to the instance:
#
#   gcloud compute ssh root@ldap
#
# 3. Run the script on the instance:
#
#   ./ldap-setup.sh
#
# 4. When prompted for choosing an LDAP admin password, enter 'password'.
#
# Note: running the script with 'gcloud compute ssh --command' doesn't work
# because 'apt-get install slapd' shows a prompt for the LDAP admin password.
#------------------------------------------------------------------------------#

set -e

# Install OpenLDAP and client tools
apt-get update
apt-get install -y slapd=2.4.45+dfsg-1ubuntu1.4 ldap-utils=2.4.45+dfsg-1ubuntu1.4

# The following changes the suffix of the main database from the default name
# (which includes the GCP project name) to dc=mycompany,dc=com.

# Export existing database entries
slapcat >data.ldif

# Kill the running OpenLDAP server
pkill -9 slapd

# Delete the existing database file
# Path is defined in in /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif
rm -f /var/lib/ldap/*

# Start up the OpenLDAP server again
# Startup command is defined in in /var/run/slapd/slapd.args, which is defined
# in /etc/ldap/slapd.d/cn\=config.ldif
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

cat <<EOF

✅ Installation successful.

You can create a user with:

  cat <<EOF >user.ldif
  dn: cn=alice,dc=mycompany,dc=com
  objectClass: top
  objectClass: inetOrgPerson
  cn: alice
  givenName: Alice
  sn: White
  userPassword: password
  mail: alice@mycompany.com
  ou: dev
  EOF
  ldapadd -x -D 'cn=admin,dc=mycompany,dc=com' -w password -f user.ldif

You can then query this user with:

  ldapsearch -x -D cn=admin,dc=mycompany,dc=com -w password \
    -b dc=mycompany,dc=com '(&(objectClass=person)(cn=alice)(userPassword=password))'

EOF

rm -f data.ldif update.ldif user.ldif
