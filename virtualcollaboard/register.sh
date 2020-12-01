#!/bin/bash

#TEXT_LOCATION=/var/www/test/test.txt
TEXT_LOCATION=/var/www/templates/test.txt

function get()
{
    echo ''
    cat /var/www/templates/Register.html
}

function post()
{
    read -n $CONTENT_LENGTH QUERY_STRING

    declare -A param
    while IFS='=' read -r -d '&' key value; do
        param["$key"]=$value
    done <<< "${QUERY_STRING}&"

    if [[ -v param[username] ]]; then
                user=$(echo "${param[username]}" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g;s/--//g')
                user=$(echo "$user" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
        else
                echo "Incomplete data"
                exit 1
    fi

    if [[ -v param[domain] ]]; then
                dom=$(echo "${param[domain]}" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g;s/--//g')
                dom=$(echo "$dom" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
        else
                echo "Incomplete data"
                exit 1
    fi

    if [[ -v param[org] ]]; then
                org=$(echo "${param[org]}" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g;s/--//g')
                org=$(echo "$org" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
        else
                echo "Incomplete data"
                exit 1
    fi

    datee=$(date)
    mess=$(printf 'Register request:\nMail: %s@%s\nOrganization: %s\nTimestamp: %s\n' $user $dom $org "$datee")
    mailAddr="virtualcollaboard@gmail.com"
    echo "$mess" | mailx -r $mailAddr -s "Register request" $mailAddr

    echo ''
    cat /var/www/templates/RegisterNotify.html
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