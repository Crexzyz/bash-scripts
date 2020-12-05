#!/bin/bash

DB_PATH=/data/spacedeck/nfs/db/passreqs.sqlite
POST_HOST=http://localhost:9666
RESET_ROUTE=/api/users/password_reset_requests
TEMP_LOG=/home/padmin/reset.log

function getTokensFromDb()
{
        # Get accounts, lock table while reading
        tokens=$(sqlite3 $DB_PATH -cmd '' 'begin;
         select token from resetrequests where status = 0;
         update resetrequests set status = 0 where status = 0;
         commit;')
}

function main()
{
        getTokensFromDb
        echo "" > $TEMP_LOG

        if [[ ! $tokens = "" ]]; then
            for token in "$tokens"; do
                # Get pass from db
                data=$(sqlite3 $DB_PATH -cmd '' 'select pass,mail from resetrequests where token = "'$token'";')
                readarray -td'|' info <<<"$data|"; unset 'info[-1]'; declare -p info;

                password="${info[0]}"
                ipaUsername=$(echo "${info[1]}" | sed 's/@.*//g' )
                # Get mail from request
                mail="${info[1]}"

                    # Post change to spacedeck
                    curl -s --request POST --header "Content-Type: application/json" --data '{"password":"'$password'"}' $POST_HOST$RESET_ROUTE/$token/confirm >> $TEMP_LOG 2>&1

                    # Post change to FreeIPA
                    echo $password | ipa user-mod $ipaUsername --password >> $TEMP_LOG 2>&1


                        # Notify
                        echo "Su clave de acceso ha sido cambiada correctamente" | mailx -r "virtualcollaboard@gmail.com" -s "Clave de acceso cambiada" $mail

                    # Remove request
                        sqlite3 $DB_PATH -cmd '' 'delete from resetrequests where token = "'$token'";'
                done
        else
                echo "No requests at" $(date) >> $TEMP_LOG 2>&1
        fi
}

main "$@"
