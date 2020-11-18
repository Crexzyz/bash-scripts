#!/bin/bash
MAIL=0
DETAILS=0

function main()
{
	if [[ $# -eq 0 ]]; then
		printHelp $0
	else
		parseArguments "$@"
	fi


	if [[ $DETAILS -eq 1 ]]; then
		hostname
		printf '\tDate\t\tMAC Address\t\tHost\t\tIP Address\tState\n'

		journalctl -u dhcpd -n 100 --no-pager > log_dhcp.txt
		awk -f dhcp.awk log_dhcp.txt
	fi
	if [[ $MAIL -eq 1 ]]; then
		echo awk -f dhcp.awk log_dhcp.txt | mail -s "message subject" username@example.com
		printf 'mandar correo\n'
	fi

}

function parseArguments()
{
	while (( "$#" )); do
	  case "$1" in
	    -m|--mail)
	      MAIL=1
	      shift
	      ;;
  	    -d|--details)
	      DETAILS=1
	      shift
	      ;;
	    -s|--server)
	      SERVER=1
	      shift
	      ;;
	    -f|--firewall)
	      FIREWALL=1
	      shift
	      ;;
  	    -p|--ports)
	      PORTS=1
	      shift
	      ;;	    
	    -d|--dst)
	      DESTINATION=1
	      shift
	      ;;  
  	    -o|--src)
	      SOURCE=1
	      shift
	      ;;
	    -l|--lines)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        LINES=$2
	        shift 2
	      else
	        echo "Error: Missing amount of lines for argument --lines" >&2
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
	echo "Usage:" $1 "<context> [lines]"
	echo "Context:"
	printf "\t%s\n" "-m --mail: Prints connection information as a client machine"
}


# Pass arguments as-is
main "$@"
