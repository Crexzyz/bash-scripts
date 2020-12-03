#!/bin/bash

POST_HOST=http://localhost:9666
HOST=http://172.24.132.17
SESSION_ROUTE=/api/sessions
DASHBOARD_ROUTE=/spaces

function page()
{
        echo ''
        cat /var/www/templates/Login.html
}

function login()
{
        read -n $CONTENT_LENGTH QUERY_STRING

        # The following lines will prevent XSS and check for valide JSON-Data.
        # But these Symbols need to be encoded somehow before sending to this script
        #QUERY_STRING_POST=$(echo "$QUERY_STRING_POST" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g' ) # removes some symbols (like \ * ` $ ') to prevent XSS with Bash and SQL.
        #QUERY_STRING_POST=$(echo "$QUERY_STRING_POST" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba') # removes most html declarations to prevent XSS within documents

        declare -A param
        while IFS='=' read -r -d '&' key value; do
            param["$key"]=$value
        done <<< "${QUERY_STRING}&"

        username=$(echo "${param[username]}@${param[domain]}")
        password=${param[password]}
        cookie=$(curl -s --request POST --header "Content-Type: application/json" --data '{"email":"'$username'","password":"'$password'"}' $POST_HOST$SESSION_ROUTE | jq -r ".token")

        if [[ $cookie = "" ]]; then
                page
        else
                echo "Set-Cookie: sdsession=$cookie; Expires=; HttpOnly"
                echo "Location: $HOST$DASHBOARD_ROUTE"
                echo ''
        fi

}

function main()
{
        echo "Content-type: text/html"

        if [[ $REQUEST_METHOD = "POST" ]]; then
                login
        else
                page
        fi
}

main "$@"