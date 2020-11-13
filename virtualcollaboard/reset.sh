#!/bin/bash

HOST=http://172.17.233.251:8080
RESET_ROUTE=/api/users/password_reset_requests
DASHBOARD_ROUTE=/spaces

function notify()
{
        echo ''
        cat /var/www/templates/ResetNotify.html
}

function page()
{
        echo ''
        cat /var/www/templates/ResetMail.html
}

function login()
{
        read -n $CONTENT_LENGTH QUERY_STRING

        declare -A param
        while IFS='=' read -r -d '&' key value; do
            param["$key"]=$value
        done <<< "${QUERY_STRING}&"

        # Send notify to Spacedeck server
                curl -s --request POST $HOST$RESET_ROUTE?email=${param[username]}%40${param[domain]} > /dev/null

                # Send mail to user
                # Pending

                notify
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