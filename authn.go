// Kubernetes webhook token authentication service with LDAP as a backend.
//
// Usage: authn <LDAP-IP> <KEY-FILE> <CERT-FILE>
//
// You can create a private ky and self-signed certificate with:
//
//   openssl req -x509 -newkey rsa:2048 -nodes -subj "/CN=localhost" -keyout key.pem -out cert.pem
//
package main

import (
	"encoding/json"
	"fmt"
	"github.com/go-ldap/ldap"
	"io/ioutil"
	"k8s.io/api/authentication/v1"
	"log"
	"net/http"
	"os"
	"strings"
)

var ldapServerURL string

func main() {
	ldapServerURL = "ldap://" + os.Args[1]
	log.Printf("LDAP backend: %s\n", ldapServerURL)
	http.HandleFunc("/", httpHandler)
	log.Println("Listening on port 443 for requests...")
	log.Fatal(http.ListenAndServeTLS(":443", os.Args[3], os.Args[2], nil))
}

func httpHandler(w http.ResponseWriter, r *http.Request) {

	// Read POST request body
	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Receiving: %s\n", string(b))

	// Translate POST request body to TokenReview object
	// Type definition: https://github.com/kubernetes/api/blob/master/authentication/v1/types.go
	var tr v1.TokenReview
	err = json.Unmarshal(b, &tr)
	if err != nil {
		log.Fatal(err)
	}

	// Extract username and password from the token in the TokenReview object
	s := strings.SplitN(tr.Spec.Token, ":", 2)
	if len(s) != 2 {
		log.Fatal("Badly formatted token")
	}
	username, password := s[0], s[1]

	// Validate username and password against the LDAP directory
	userInfo := ldapQuery(username, password)

	// Set status of TokenReview
	if userInfo == nil {
		tr.Status.Authenticated = false
	} else {
		tr.Status.Authenticated = true
		tr.Status.User = *userInfo
	}

	// Translate the TokenReview back to JSON
	b, err = json.Marshal(tr)
	if err != nil {
		log.Fatal(err)
	}

	// Send the JSON TokenReview back to the API server
	fmt.Fprintln(w, string(b))
	log.Printf("Returning: %s\n", string(b))
}

// Check whether there exists an LDAP entry with the specified username and
// password. Return a UserInfo object with additional informatin about the user
// if an entry exists, and nil otherwise.
func ldapQuery(username string, password string) *v1.UserInfo {

	// Connet to LDAP server
	l, err := ldap.DialURL(ldapServerURL)
	if err != nil {
		log.Fatal(err)
	}
	defer l.Close()

	// Authenticate as admin
	err = l.Bind("cn=admin,dc=mycompany,dc=com", "password")
	if err != nil {
		log.Fatal(err)
	}

	// Perform search operation
	searchRequest := ldap.NewSearchRequest(
		"dc=mycompany,dc=com",  // Search base
		ldap.ScopeWholeSubtree, // Search scope
		ldap.NeverDerefAliases, // Dereference aliases
		0,                      // Size limit (0 = no limit)
		0,                      // Time limit (0 = no limit)
		false,                  // Types only
		fmt.Sprintf("(&(objectClass=inetOrgPerson)(cn=%s)(userPassword=%s))", username, password), // Filter
		nil, // Attributes (nil = all user attributes)
		nil, // Additional 'Controls'
	)
	result, err := l.Search(searchRequest)
	if err != nil {
		log.Fatal(err)
	}

	// Return UserInfo if credentials are correct, and nil otherwise
	if len(result.Entries) == 0 {
		return nil
	} else {
		return &v1.UserInfo{
			Username: username,
			UID:      username,
			Groups:   result.Entries[0].GetAttributeValues("ou"),
		}
	}
}
