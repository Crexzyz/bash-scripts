#!/bin/bash

POST_HOST=http://localhost:9666
HOST=https://172.24.132.17
RESET_ROUTE=/api/users/password_reset_requests
RESET_PAGE=/u/reset
LOGIN_PAGE=/u/login
DB_PATH=/data/spacedeck/nfs/db/database.sqlite
DB_PASS_PATH=/data/spacedeck/nfs/db/passreqs.db

function sanitize()
{
    if [[ ! "$1" = "" ]]; then
        # The following lines will prevent XSS and check for valide JSON-Data.
        # But these Symbols need to be encoded somehow before sending to this script
        sanitized=$(echo "$1" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g;s/--//g')
        sanitized=$(echo "$sanitized" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
    else
        if [[ $sanError -eq 0 ]]; then
            sanError=1
        fi
    fi
}

function getPostInput()
{
    sanError=0
    # Sanitize input
    sanitize "${param[t]}"
    token="$sanitized"

    sanitize "${param[pass]}"
    password="$sanitized"
}

function post()
{
    read -n $CONTENT_LENGTH QUERY_STRING

    declare -A param
    while IFS='=' read -r -d '&' key value; do
        param["$key"]=$value
    done <<< "${QUERY_STRING}&"

    getPostInput

    if [[ $sanError -eq 0 ]]; then
        mail=$(sqlite3 $DB_PATH -cmd '' 'select email from users where password_reset_token = "'$token'";')

        sqlite3 $DB_PASS_PATH -cmd '' 'insert into resetrequests values ("'$token'", "'$password'", "'$mail'", 0);'        

        echo "Location: $HOST$LOGIN_PAGE"
        echo ''
    else
        echo ''
        echo "Datos incompletos"
    fi

}

function get()
{
    STRING=$QUERY_STRING
    declare -A param
    while IFS='=' read -r -d '&' key value; do
        param["$key"]=$value
    done <<< "$STRING&"

    sanError=0
    # Sanitize input
    sanitize "${param[t]}"
    token="$sanitized"

    if [[ $sanError -eq 0 ]]; then
        # Check if code exists in db
        mail=$(sqlite3 $DB_PATH -cmd '' 'select email from users where password_reset_token = "'$token'";')
        echo ''
        sed "s/{mail}/$mail/g;s/{t}/$token/g" /var/www/templates/ResetInput.html
    else
        echo "Location: $HOST$RESET_PAGE"
        echo ''
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