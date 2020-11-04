#!/bin/bash
PARAMS=""
CLIENT=0
SERVER=0
FIREWALL=0
LINES=0
PORTS=0

function main()
{
	if [[ $# -eq 0 ]]; then
		printHelp $0
	else
		parseArguments "$@"
	fi

	if [[ $CLIENT -eq 1 ]]; then
		if [[ $PORTS -eq 1 ]]; then
			check_client P
		else
			check_client
		fi
	fi
	if [[ $SERVER -eq 1 ]]; then
		echo "Server"
	fi
	if [[ $FIREWALL -eq 1 ]]; then
		echo "Firewall"
	fi
}

function check_client()
{
	if [[ $1 = "P" ]]; then
		printf 'Ports\tConnections\n'
	else
		printf 'Address\t\tConnections\n'
	fi

	if [[ $LINES -gt 0 ]]; then
		awk -v type=$1 -f Common.awk -f Client.awk nf_conntrack.txt | sort -nrk2 | head -$LINES
	else
		awk -v type=$1 -f Common.awk -f Client.awk nf_conntrack.txt | sort -nrk2
	fi	
}

function parseArguments()
{
	while (( "$#" )); do
	  case "$1" in
	    -c|--client)
	      CLIENT=1
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
	printf "\t%s\n" "-c --client: Prints connection information as a client machine"
	printf "\t%s\n" "-s --server: Prints connection information as a server machine"
	printf "\t%s\n" "-f --firewall: Prints connection information as a firewall machine"
	printf "\t%s\n" "-p --ports: Prints port information instead of IP addresses"
	echo "Lines:"
	printf "\t%s\n" "-l --lines N: Prints the top N lines"
}

# Pass arguments as-is
main "$@"