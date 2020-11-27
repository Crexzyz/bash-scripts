#!/bin/bash
PARAMS=""
CLIENT=0
SERVER=0
FIREWALL=0
LINES=0
PORTS=0
IP=$(hostname -I)
IP=$(echo $IP | sed -r 's/ /,/g')
DESTINATION=0
SOURCE=0
#CONNTRACK_FILE="nf_conntrack.txt" # Testing file
CONNTRACK_FILE="/proc/net/nf_conntrack" # Production file
#ABSPATH="." # Testing path (same directory)
ABSPATH="/home/vadmin/scripts/network" # Production path
#LOGPATH="./network.log"
LOGPATH="/home/vadmin/scripts/temps/network.log"

function main()
{
	echo "" > $LOGPATH

	if [[ $# -eq 0 ]]; then
		printHelp $0
		exit 0
	else
		parseArguments "$@"
	fi

	if [[ $CLIENT -eq 1 ]]; then
		if [[ $PORTS -eq 1 ]]; then
			check_client P &>> $LOGPATH
		elif [[ -z "$IP"  ]]; then
			printf 'You must specify IP/IPs\n' &>> $LOGPATH
		else
			check_client &>> $LOGPATH
		fi
	fi
	if [[ $SERVER -eq 1 ]]; then
		echo ""
		if [[ $PORTS -eq 1 ]]; then
			check_server P &>> $LOGPATH
		elif [[ -z "$IP"  ]]; then
			printf 'You must specify IP/IPs\n' &>> $LOGPATH
		else
			check_server &>> $LOGPATH
		fi
	fi
	if [[ $FIREWALL -eq 1 ]]; then
		if [[ $DESTINATION -eq 1 ]]; then
			check_firewall D &>> $LOGPATH
		elif [[ -z "$IP"  ]]; then
			printf 'You must specify IP/IPs\n' &>> $LOGPATH
		else
			if [[ $DESTINATION -eq 1 ]] || [[ $SOURCE -eq 1 ]]; then
				check_firewall S &>> $LOGPATH
			else
				printf 'You must specify a source or destination address\n' &>> $LOGPATH
			fi
		fi
	fi

	cat $LOGPATH
}

function check_client()
{
	if [[ $1 = "P" ]]; then
		printf 'Address\t\tProtocol\tPort\tConnections (Client)\n'
	else
		printf 'Address\t\tConnections (Client)\n'
	fi

	# Get local IPs splitted by commas

	# TEMPORAL LOCALIP FOR TESTING
	# localIPs="192.168.13.1,192.168.15.1,172.24.132.16"

	local sortType=""
	if [[ $PORTS -eq 1 ]]; then
		sortType=-nrk4
	else
		sortType=-nrk2
	fi

	if [[ $LINES -gt 0 ]]; then
		awk -v type=$1 -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Client.awk $CONNTRACK_FILE | sort $sortType | head -$LINES
	else
		awk -v type=$1 -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Client.awk $CONNTRACK_FILE | sort $sortType
	fi	
}

function check_server()
{
	if [[ $1 = "P" ]]; then
		printf 'Address\t\tProtocol\tPort\tConnections (Server)\n'
	else
		printf 'Address\t\tConnections (Server)\n'
	fi

	# Get local IPs splitted by commas
	local serverIPs=$(hostname -I)
	serverIPs=${serverIPs// /,}

	# TEMPORAL LOCALIP FOR TESTING
	# serverIPs="172.24.132.16,192.168.13.30"

	local sortType=""
	if [[ $PORTS -eq 1 ]]; then
		sortType=-nrk4
	else
		sortType=-nrk2
	fi

	if [[ $LINES -gt 0 ]]; then
		awk -v type=$1 -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Server.awk $CONNTRACK_FILE | sort $sortType | head -$LINES
	else
		awk -v type=$1 -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Server.awk $CONNTRACK_FILE | sort $sortType
	fi	
}
function check_firewall()
{
	local sortType="-nrk4"

	if [[ $1 = "S" ]]; then
		printf 'Source Address\t\t%s\n-----------------------------------------------------\nConnect to\t\tProtocol\tPort\tConnections\n%s\n' $IP
		awk -v type="S" -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Client.awk $CONNTRACK_FILE | sort $sortType

	else
		printf 'Destination Address\t\t%s\n-----------------------------------------------------\nConnect to\t\tProtocol\tPort\tConnections\n%s\n' $IP
		awk -v type="D" -v ips=$IP -f $ABSPATH/Common.awk -f $ABSPATH/Server.awk $CONNTRACK_FILE | sort $sortType

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
	    --src)
	      SOURCE=1
	      shift
	      ;;	    
	    --dst)
	      DESTINATION=1
	      shift
	      ;;  
	    -i|--ip)
		  if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        IP=$2
	        shift 2
	      else
	        echo "Error: Missing IP Address" >&2
	        exit 1
	      fi
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
	printf "\t%s\n" "-p --ports: Prints port information instead of IP addresses"
	printf "\t%s\n" "-f --firewall: Prints connection information as a firewall machine"
	printf "\t%s\n" "-i --ip: IP addresses"
	printf "\t%s\n" "--src: Soucer IP addresses"
	printf "\t%s\n" "--dst: Destination IP addresses"
	echo "Lines:"
	printf "\t%s\n" "-l --lines N: Prints the top N lines"
}

# Pass arguments as-is
main "$@"
