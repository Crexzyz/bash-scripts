#!/bin/bash

POST_HOST=http://localhost:9666
HOST=https://172.24.132.55
RESET_ROUTE=/api/users/password_reset_requests
RESET_PAGE=/u/reset
LOGIN_PAGE=/u/login
DB_PATH=/data/spacedeck/nfs/db/database.sqlite
PARAMS=""
password=""
token=""

function parseArguments()
{
    while (( "$#" )); do
      case "$1" in
        -p|--password)
          if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            password=$2
            shift 2
          else
            echo "Error: Missing password for argument $1" >&2
            exit 1
          fi
          ;;
        -t|--token)
          if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            token=$2
            shift 2
          else
            echo "Error: Missing token for argument $1" >&2
            exit 1
          fi
          ;;
        -*|--*=) # unsupported flags
          echo "Error: Unsupported flag $1" >&2
          exit 1
          ;;
        *) # preserve positional arguments
          PARAMS="$PARAMS $1"
          shift
          ;;
      esac
    done

    eval set -- "$PARAMS"
}

function validateFiles()
{
    if test -f "$password"; then
        password="$(cat $password)"
    else
        echo "Password file does not exist"
        exit 1
    fi

    if test -f "$token"; then
        token="$(cat $token)"
    else
        echo "Token file does not exist"
        exit 1
    fi
}

function changePassword
{
    echo "Changing Spacedeck password..."
    # Post change to spacedeck
    curl -s --request POST --header "Content-Type: application/json" --data '{"password":"'$password'"}' $POST_HOST$RESET_ROUTE/$token/confirm
    echo ""

    echo "Changing IPA password..."
    # Post change to FreeIPA
    echo $password | ipa user-mod $ipaUsername --password
}

function printHelp()
{
    echo "Usage:" $1 "<password file> <token file>"
    echo "Parameters:"
    printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-t --token " "Path to token file" "Sets the path where the reset token is going to be read"
    printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-p --password " "Path to password file" "Sets the path where the new password is going to be read"
}

function main()
{
    if [[ ! $(hostname) = "spacedeck01.virtualcollaboard.com" ]] && [[ ! $(hostname) = "spacedeck02.virtualcollaboard.com" ]] ; then
        echo "This command must be run from a Spacedeck server"
    else
        if [[ $# -eq 0 ]]; then
            printHelp $0
        else
            parseArguments "$@"
            validateFiles  

            # Get user based on its token
            ipaUsername=$(sqlite3 $DB_PATH -cmd '' 'select nickname from users where password_reset_token = "'$token'";')

            if [[ ! $ipaUsername = "" ]]; then
                echo "Changing password of user" $ipaUsername
                read -p "Is this ok? [y/n] " -n 1 -r
                echo ""

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    changePassword
                    echo "Done."
                fi
            else
                echo "User not found in the Spacedeck database with the token provided"
            fi
        fi
    fi
}

main "$@"
