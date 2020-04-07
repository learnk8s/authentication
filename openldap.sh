#!/bin/bash
#
# Install OpenLDAP on Ubuntu:
#
# Upload and run the script on a GCP compute instance named 'ldap' with:
#
#   gcloud compute scp openldap.sh root@ldap:
#   gcloud compute ssh root@ldap --command ./openldap.sh
#
#------------------------------------------------------------------------------#

set -e

# Preset package configuration
cat <<EOF | debconf-set-selections
slapd slapd/password1 password adminpassword
slapd slapd/password2 password adminpassword
slapd slapd/domain string mycompany.com
slapd shared/organization string mycompany.com
EOF

# Install the OpenLDAP package
apt-get update
apt-get install -y slapd

cat <<EOF

✅ Installation successful

To create an example user, save the following in a file named 'alice.ldif':

  dn: cn=alice,dc=mycompany,dc=com
  objectClass: top
  objectClass: inetOrgPerson
  cn: alice
  gn: Alice
  sn: Wonderland
  userPassword: alicepassword
  ou: dev

Then, create the entry with:

  ldapadd -H ldap://<IP-ADDRESS> -x -D 'cn=admin,dc=mycompany,dc=com' -w adminpassword -f alice.ldif

You can then query the entry with:

  ldapsearch -H ldap://<IP-ADDRESS> -LLL -x -D cn=admin,dc=mycompany,dc=com -w adminpassword \\
    -b dc=mycompany,dc=com '(&(objectClass=person)(cn=alice)(userPassword=alicepassword))'

EOF
