#!/bin/bash

POST_HOST=http://localhost:9666
HOST=http://172.24.132.17
SESSION_ROUTE=/api/sessions
DASHBOARD_ROUTE=/spaces
ERROR_TEMPLATE='<div class="mx-auto shadow-sm p-3 w-50 alert alert-danger" role="alert">{errmess}</div>'

function page()
{
        echo ''
        page=$(cat /var/www/templates/Login.html | sed "s/{err}//g")
        echo "$page"
}

function errorPage()
{
        echo ''
        errMessage=$(echo $ERROR_TEMPLATE | sed "s|{errmess}|$1|g")
        page=$(cat /var/www/templates/Login.html | sed "s|{err}|$errMessage|g")
        echo "$page"
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

function getInput()
{
        sanError=0
    # Sanitize input
    sanitize "${param[username]}"
    username="$sanitized"

    sanitize "${param[domain]}"
    domain="$sanitized"

    sanitize "${param[password]}"
    password="$sanitized"
}

function authLdap()
{
        user="$1"
        pass="$2"

        result=$(ldapsearch -D "uid=$user,cn=users,cn=accounts,dc=virtualcollaboard,dc=com" \
         -b 'cn=accounts,dc=virtualcollaboard,dc=com' \
         "uid=$user" \
         -w "$pass" 2>&1 )

        ldapError=$?

        if [[ $ldapError -eq 0 ]]; then
                memberOf=$(echo "$result" | grep "^memberOf: cn=spacedeck-users")
                if [[ $memberOf = "" ]]; then
                        ldapMessage="Error: el usuario $user no está autorizado a usar el servicio"
                fi
        elif [[ $ldapError -eq 53 ]]; then
                ldapMessage="Error: muchos intentos de inicio de sesión fallidos, contacte a un administrador"
        else
                ldapMessage="Error desconocido, contacte a los administradores de virtualcollaboard"
        fi
}

function login()
{
        read -n $CONTENT_LENGTH QUERY_STRING

        # Read CGI params
        declare -A param
        while IFS='=' read -r -d '&' key value; do
            param["$key"]=$value
        done <<< "${QUERY_STRING}&"

        getInput

        if [[ $sanError -eq 0 ]]; then
                # Authenticate against FreeIPA
                authLdap "$username" "$password"

                if [[ ! $ldapError -eq 0 ]]; then
                        errorPage "$ldapMessage"
                else
                        fullUsername=$(echo $username@$domain)

                        cookie=$(curl -s --request POST --header "Content-Type: application/json" --data '{"email":"'$fullUsername'","password":"'$password'"}' $POST_HOST$SESSION_ROUTE)
                        parsedCookie=$(echo $cookie | jq -r ".token")

                        if [[ $cookie = "Not Found" ]]; then
                                errorPage "Error: el usuario no está registrado en la base de datos de Spacedeck"
                        else
                                echo "Set-Cookie: sdsession=$parsedCookie; Expires=; HttpOnly"
                                echo "Location: $HOST$DASHBOARD_ROUTE"
                                echo ''
                        fi
                fi
        else
                errorPage "Error: datos inválidos"
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
