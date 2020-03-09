// The Kubernetes-LDAP authentication service.
//
// The command requires a single argument, which is the IP address of the LDAP
// server. Logs are written to stderr.
//
// IMPORTANT: before running this command, generate a certificate and private
// key in the same directory as the binary with the following command:
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
	log.Printf("Using LDAP server %s\n", ldapServerURL)
	http.HandleFunc("/", httpHandler)
	log.Println("Listening on port 443 for requests")
	log.Fatal(http.ListenAndServeTLS(":443", "cert.pem", "key.pem", nil))
}

func httpHandler(w http.ResponseWriter, r *http.Request) {
	// Read POST request body
	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Fatal(err)
	}

	// Translate POST request body to TokenReview object
	// Type definition: https://github.com/kubernetes/api/blob/master/authentication/v1/types.go
	var tr v1.TokenReview
	err = json.Unmarshal(b, &tr)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Request (token): %s\n", tr.Spec.Token)

	// Extract username and password from the token
	// TODO: base64-encode "username:password" string (like HTTP Basic auth)
	s := strings.SplitN(tr.Spec.Token, ":", 2)
	if len(s) != 2 {
		log.Fatal("Invalid token")
	}
	username, password := s[0], s[1]
	tr.Spec = v1.TokenReviewSpec{}

	// Verify username and password with LDAP
	userInfo := verifyUser(username, password)

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
	log.Printf("Response: %s\n", string(b))
}

func verifyUser(username string, password string) *v1.UserInfo {
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
	filter := fmt.Sprintf("(&(objectClass=inetOrgPerson)(cn=%s)(userPassword=%s))", username, password)
	searchRequest := ldap.NewSearchRequest(
		"dc=mycompany,dc=com",  // Search base
		ldap.ScopeWholeSubtree, // Search scope
		ldap.NeverDerefAliases, // Dereference aliases
		0,                      // Size limit (0 = no limit)
		0,                      // Time limit (0 = no limit)
		false,                  // Types only
		filter,                 // Filter
		nil,                    // Attributes (nil = all user attributes)
		nil,                    // Additional 'Controls'
	)
	result, err := l.Search(searchRequest)
	if err != nil {
		log.Fatal(err)
	}

	// Return UserInfo if credentials are correct, and nil otherwise
	if len(result.Entries) == 1 {
		return &v1.UserInfo{
			Username: username,
			UID:      username,
			Groups:   result.Entries[0].GetAttributeValues("ou"),
		}
	} else {
		return nil
	}
}
