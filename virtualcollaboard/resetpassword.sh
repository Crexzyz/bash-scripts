#!/bin/bash

HOST=http://172.17.233.251
SPACEDECK_PORT=8080
RESET_ROUTE=/api/users/password_reset_requests
RESET_PAGE=/reset
LOGIN_PAGE=/login

function post()
{
    read -n $CONTENT_LENGTH QUERY_STRING

    declare -A param
    while IFS='=' read -r -d '&' key value; do
        param["$key"]=$value
    done <<< "${QUERY_STRING}&"

    token=${param[t]}
    password=${param[pass]}

    # Post change to spacedeck
    curl -s --request POST --header "Content-Type: application/json" --data '{"password":"'$password'"}' $HOST:$SPACEDECK_PORT$RESET_ROUTE/$token/confirm > /dev/null

    echo "Location: $HOST$LOGIN_PAGE"
    echo ''
}

function get()
{
    STRING=$QUERY_STRING
    declare -A param
    while IFS='=' read -r -d '&' key value; do
        param["$key"]=$value
    done <<< "$STRING&"

    if [[ -v param[t] ]]; then
        # removes some symbols (like \ * ` $ ') to prevent XSS with Bash and SQL.
        token=$(echo "${param[t]}" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g;s/--//g')
        # removes most html declarations to prevent XSS within documents
        token=$(echo "$token" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
    else
        token=";aa"
    fi

    # Check if code exists in db
    mail=$(sqlite3 /home/root/spacedeck/spacedeck-open/nfs/db/database.sqlite -cmd '' 'select email from users where password_reset_token = "'$token'";')


    if [[ $mail = "" ]]; then
        echo "Location: $HOST$RESET_PAGE"
        echo ''
    else
        echo ''
        sed "s/{mail}/$mail/g;s/{t}/$token/g" ../../templates/ResetInput.html
    fi
}

function main()
{
    echo "Content-type: text/html"

    if [[ $REQUEST_METHOD = "POST" ]]; then
            post
    else
            get
    fi
}

main "$@"