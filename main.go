package main

import (
	//"fmt"
	"github.com/go-ldap/ldap"
	"log"
)

func main() {

	// Establish connetion to LDAP server
	l, err := ldap.DialURL("ldap://34.65.192.69")
	if err != nil {
		log.Fatal(err)
	}
	defer l.Close()

	// Authenticate as admin
	err = l.Bind("cn=admin,dc=mycompany,dc=com", "test")
	if err != nil {
		log.Fatal(err)
	}

	searchRequest := ldap.NewSearchRequest(
		"dc=mycompany,dc=com",  // Search base
		ldap.ScopeWholeSubtree, // Search scope
		ldap.NeverDerefAliases, // Dereference aliases
		0,                      // Size limit (0 = no limit)
		0,                      // Time limit (0 = no limit)
		false,                  // Return attribute types only
		//"(&(objectClass=person)(cn=weibeld)(userPassword=test))",  // Filter
		"(objectClass=person)",
		nil, // Attributes (nil = all user attributes)
		nil, // Additional Controls
	)

	result, err := l.Search(searchRequest)
	if err != nil {
		log.Fatal(err)
	}

	result.PrettyPrint(0)

	/*for _, entry := range result.Entries {
		fmt.Printf("%s: %v\n", entry.DN, entry.GetAttributeValue("cn"))
	}*/
}
