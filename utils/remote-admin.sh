#!/bin/bash

hosts=""
password=""
hostsFile=""
declare -A components=( [Network]="" [Logs]="" [Hardware]="" )
delay="0"
commands=""
IDENTITY_FILE="/root/.ssh/id_rsa"
declare -A commandsArr=( [0]="" [1]="" [2]="" [3]="" [4]="" )

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
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ] && [ -n "$3" ] && [ ${3:0:1} == "{" ]; then
	        if [[ ! $2 = "Network" ]] && [[ ! $2 = "Logs" ]] && [[ ! $2 = "Hardware" ]] ; then
				echo "Error: unknown component ($2)"
				exit 1
			else
				components[$2]=$(echo $3 | sed "s/{//g;s/}//g")
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
	printf "\t%s\n" "$1 -h gestion02 -c Network '{-c -p -l 10}' -p pass.txt"
	printf "\t%s\n" "$1 -f servers.txt -c Network '{-c -p -l 10}' -c Logs '{-a}' -p pass.txt"
	printf "\t%s\n" "$1 -f servers.txt -c Hardware '{-c -r}' -d 10"
	echo "Note that components' parameters must be enclosed between '{' and '}'"
}

function validateArgumentsData()
{
	if [[ $hosts = "" ]] && [[ ! -f "$hostsFile" ]]; then
		echo "Error: no hosts defined" >&2
		exit 1
	fi

	if [[ ! -f "$password" ]]; then
		echo "Error: password file does not exist" >&2
		exit 1
	else
		password=$(cat $password)
	fi

	if [[ -f "$hostsFile" ]]; then
		hosts="$hosts $(cat $hostsFile)"
	fi

	if [[ ${components[Network]} = "" ]] && [[ ${components[Logs]} = "" ]] && [[ ${components[Hardware]} = "" ]]; then
		echo "Error: no component set to run" >&2
		exit 1
	fi

	if [[ ! ${components[Hardware]} = "" ]] && [[ $delay = "" ]]; then
		echo "Error: delay parameter is needed when running the hardware monitoring command" >&2
   		exit 1
	else
		if [[ ! $delay = "" ]] && [[ ! $delay =~ ^[0-9]+$ ]]; then
	   		echo "Error: delay value is not a number" >&2
	   		exit 1
		fi
	fi
}

function askConfirmation()
{
	echo "Hosts:"$hosts

	echo "Components:"
	for component in "${!components[@]}"; 
	do
		if [[ ! ${components[$component]} = "" ]]; then
			printf "\t" && echo $component ${components[$component]}
		fi
	done

	if [[ ! $delay = "" ]]; then
		echo "Delay:" $delay
	fi

	read -p "Is this ok? [y/n] " -n 1 -r
	echo ""
}

function prepareCommands()
{
	local realCommand=""
	local commandIndex=1
	for component in "${!components[@]}"; 
	do
		if [[ $component = "Network" ]]; then
			realCommand="/home/vadmin/scripts/network/Network.sh"
		elif [[ $component = "Logs" ]]; then
			realCommand="/home/vadmin/scripts/logs/Logs.sh"
		elif [[ $component = "Hardware" ]]; then
			realCommand="/home/vadmin/scripts/hardware/Hardware.sh"
		fi

		if [[ ! ${components[$component]} = "" ]]; then
			commands="$commands sudo $realCommand ${components[$component]} & "
		fi
		realCommand=""
	done
}

function runCommands()
{
	for host in $hosts; 
	do
		# echo "Connecting to $host"

		# ssh -q -i $IDENTITY_FILE vadmin@$host exit > /dev/null 2>&1
  #       if [[ $? -eq 255 ]]; then
  #       	echo "Error: cannot connect to $host, skipping"
  #       	continue
  #       fi

		echo "Running commands in $host"
		echo running "ssh -i $IDENTITY_FILE vadmin@$host echo $password | $commands"
	done
}

function main()
{
	if [[ $# -eq 0 ]]; then
		printHelp $0
	else
		parseArguments "$@"
		validateArgumentsData
		askConfirmation

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			prepareCommands
			runCommands

			sleep $delay
		fi
	fi
}

main "$@"