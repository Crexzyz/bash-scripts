#!/bin/bash

hosts=""
password=""
hostsFile=""
components=( [Network]="" [Logs]="" [Hardware]="" )
delay=""

function parseArguments()
{
	while (( "$#" )); do
	  case "$1" in
	    -p|--password)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        password=$2
	        shift 2
	      else
	        echo "Error: Missing password file for argument $1" >&2
	        exit 1
	      fi
	      ;;
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
	        hostsFile=$2
	        shift 2
	      else
	        echo "Error: Missing hosts files for argument $1" >&2
	        exit 1
	      fi
	      ;;
	    -c|--component)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ] && [ -n "$3" ] && [ ${3:0:1} != "-" ]; then
	        if [[ ! $2 = "Network" ]] && [[ ! $2 = "Logs" ]] && [[ ! $2 = "Hardware" ]] ; then
				echo "Error: unknown component ($2)"
				exit 1
			else
				components[$2]=$3
			fi
	        shift 3
	      else
	        echo "Error: Missing component type or component arguments for option $1" >&2
	        exit 1
	      fi
	      ;;
	    -d|--delay)
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        delay=$2
	        shift 2
	      else
	        echo "Error: Missing delay for argument $1" >&2
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
	echo -e "\e[7mRemote administration - run Virtualcollaboard administration scripts from a centralized machine\e[0m"
	echo ""
	echo "Usage:" $1 "<hosts> <component> <password> [options]"
	echo "Hosts:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-h --host " "FQDN | IP address" "Sets a host to install the administration scripts, can be used multiple times"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-f --file " "Path to file" "Sets a host file to install the administration scripts to each host"
	echo "Components:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-c --component " "component component-arguments" "Sets the component to run and its arguments"
	printf "\t\t%s%s\n" "Available monitoring components: " "Network, Logs, Hardware"	
	echo "Password:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-p --password " "Path to file" "Sets the sudo password file that the script will use"
	echo "Options:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-d --delay " "Seconds" "Sets time in seconds that the script will wait to retrieve the results of the scripts"
	echo ""
	echo "Examples:"
	printf "\t%s\n" "$1 -h gestion02 -c Network \"-c -p -l 10\" -p pass.txt"
	printf "\t%s\n" "$1 -f servers.txt -c Network \"-c -p -l 10\" -c Logs \"-a\" -p pass.txt"
	printf "\t%s\n" "$1 -f servers.txt -c Hardware \"-c -r\" -d 10"
}

function validateArgumentsData()
{
	if [[ ! -f "$password" ]]; then
		echo "Error: password file does not exist" >&2
		exit 1
	else
		password=$(cat $password)
	fi

	if [[ ${components[Network]} = "" ]] && [[ ${components[Logs]} = "" ]] && [[ ${components[Hardware]} = "" ]]; then
		echo "Error: no component set to run" >&2
		exit 1
	fi

	if [[ $hosts = "" ]] && [[ ! -f "$hosts_file" ]]; then
		echo "Error: no hosts defined" >&2
		exit 1
	fi

	if [[ ! $delay = "" ]] && [[ ! $delay =~ ^[0-9]+$ ]]; then
   		echo "Error: delay value is not a number" >&2
   		exit 1
	fi
}

function main()
{
	if [[ $# -eq 0 ]]; then
		printHelp $0
	else
		parseArguments "$@"
		validateArgumentsData
	fi
}

main "$@"