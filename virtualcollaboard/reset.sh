#!/bin/bash

POST_HOST=http://localhost:9666
HOST=https://172.24.132.55
RESET_ROUTE=/api/users/password_reset_requests
DB_PATH=/data/spacedeck/nfs/db/database.sqlite

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

function prepareMessage()
{
    resetLinkMessage=$(printf "Hola %s\n\nHaga click en este enlace para reiniciar su clave de acceso:\n$HOST/u/resetpassword?t=%s\n\n- El equipo de Virtualcollaboard" $1 $2)
}

function getInput()
{
    sanError=0
    # Sanitize input
    sanitize "${param[username]}"
    username="$sanitized"

    sanitize "${param[domain]}"
    domain="$sanitized"
}


function login()
{
        read -n $CONTENT_LENGTH QUERY_STRING

        declare -A param
        while IFS='=' read -r -d '&' key value; do
            param["$key"]=$value
        done <<< "${QUERY_STRING}&"

        getInput

        if [[ $sanError -eq 0 ]]; then
            fullUsername="$username%40$domain"
            # Send notify to Spacedeck server
            curl -s --request POST $POST_HOST$RESET_ROUTE?email=$fullUsername &> /dev/null
            email="$username@$domain"
            # Get token from db
            token=$(sqlite3 $DB_PATH -cmd '' 'select password_reset_token from users where email = "'$email'";')

            if [[ ! "$token" = "" ]]; then
                prepareMessage "$username" "$token"

                # Send mail to user
                echo "$resetLinkMessage" | mailx -r "virtualcollaboard@gmail.com" -S 'charset=UTF-8' -s "Virtualcollaboard - Reiniciar clave de acceso" $email
            fi

            notify
        else
            echo ''
            echo "Datos incompletos"
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