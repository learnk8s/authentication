#!/bin/bash
#
# Install and configure an OpenLDAP server.
#
# 1. Upload script to a GCP compute instance named 'ldap' with:
#
#   gcloud compute scp openldap.sh root@ldap:
#
# 2. Log in to the instance:
#
#   gcloud compute ssh root@ldap
#
# 3. Run the script on the instance:
#
#   ./openldap.sh
#
# 4. When prompted for choosing an LDAP admin password, choose 'password'.
#
# Running the script with 'gcloud compute ssh --command' doesn't work because
# the 'slapd' package displays a TUI prompt for entering the LDAP admin password.
#------------------------------------------------------------------------------#

set -e

# Install OpenLDAP and client tools
apt-get update
apt-get install -y slapd=2.4.45+dfsg-1ubuntu1.4 ldap-utils=2.4.45+dfsg-1ubuntu1.4

#------------------------------------------------------------------------------#
# The following changes the suffix of the main database from the default name
# (which includes the GCP project name) to dc=mycompany,dc=com.
#------------------------------------------------------------------------------#

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

✅ Installation successful

To create an example user, save the following in a file named 'user.ldif':

  dn: cn=alice,dc=mycompany,dc=com
  objectClass: top
  objectClass: inetOrgPerson
  cn: alice
  gn: Alice
  sn: Wonderland
  userPassword: alicepassword
  mail: alice@mycompany.com
  ou: dev

And then create the user with:

  ldapadd -x -D 'cn=admin,dc=mycompany,dc=com' -w password -f user.ldif

You can then query the user with:

  ldapsearch -x -D cn=admin,dc=mycompany,dc=com -w password \\
    -b dc=mycompany,dc=com '(&(objectClass=person)(cn=alice)(userPassword=alicepassword))'

EOF

rm -f data.ldif update.ldif
