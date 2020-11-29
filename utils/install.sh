#!/bin/bash

params=""
hosts=""
hosts_file=""
password=""
IDENTITY_FILE="/root/.ssh/id_rsa"

folder_cmds="sudo mkdir -p /home/vadmin/scripts/ /home/vadmin/scripts/temps"
folder_cmds="$folder_cmds && sudo chown vadmin:vadmin -R /home/vadmin"
folder_cmds="$folder_cmds && sudo chmod 700 -R /home/vadmin"
folder_cmds="$folder_cmds && exit"

function parseArguments()
{
	while (( "$#" )); do
	  case "$1" in
  	    -h|--host)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        hosts="${hosts} $2"
	        shift 2
	      else
	        echo "Error: Missing host for argument $1" >&2
	        exit 1
	      fi
	      ;;
  	    -f|--file)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        hosts_file=$2
	        shift 2
	      else
	        echo "Error: Missing hosts files for argument $1" >&2
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

function printHelp()
{
	echo "Usage:" $1 "<password> <host | hosts>"
	echo "Options:"
	printf "\t%s\n\t\t%s\n" "-h --host <FQDN | Name>" "Sets a host to install the administration scripts, can be used multiple times"
	printf "\t%s\n\t\t%s\n" "-f --file <path to file>" "Sets a host file to install the administration scripts to each host"
}

function checkFiles()
{
	if [[ $hosts = "" ]] && [[ ! -f "$hosts_file" ]]; then
		echo "Error: hosts file does not exist"
		exit 1
	fi
}

function installScripts()
{
	if [[ ! $hosts_file = "" ]]; then
		hosts=$(cat $hosts_file)
	fi

	for host in $hosts
	do
        echo "Connecting to $host"
        ssh -q -i $IDENTITY_FILE vadmin@$host exit > /dev/null 2>&1

        if [[ $? -eq 255 ]]; then
        	echo "Error: cannot connect to $host, skipping"
        	continue
        fi

        echo "Creating folders..."
        ssh -i $IDENTITY_FILE vadmin@$host "$folder_cmds"

        echo "Copying files..."

        # Commented until the scripts are ready
        scp -q -i $IDENTITY_FILE -r ../network/ vadmin@$host:/home/vadmin/scripts/
        scp -q -i $IDENTITY_FILE -r ../monitoring/ vadmin@$host:/home/vadmin/scripts/

        echo "Installing cron job for ssh"
        echo "0 21 * * * root /home/vadmin/scripts/monitoring/ssh/ssh.sh -m virtualcollaboard@gmail.com" > /etc/cron.d/ssh-check
	done
}

function main()
{
	if [[ $# -eq 0 ]]; then
		printHelp $0
	else
		parseArguments "$@"
		checkFiles
		installScripts
	fi
}

main "$@"
