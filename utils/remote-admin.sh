#!/bin/bash

hosts=""
password=""
mailResults=""
hostsFile=""
declare -A components=( [Network]="" [DHCP]="" [SSH]="" [Hardware]="" )
delay="0"
commands=""
IDENTITY_FILE="/root/.ssh/id_rsa"
declare -A commandsArr=( [0]="" [1]="" [2]="" [3]="" [4]="" )

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
	    -m|--mail)
	      mail=1
	      shift
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
	        if [[ ! $2 = "Network" ]] && [[ ! $2 = "DHCP" ]] && [[ ! $2 = "SSH" ]] && [[ ! $2 = "Hardware" ]] ; then
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
	echo "Usage:" $1 "<hosts> <component> [options]"
	echo "Hosts:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-h --host " "FQDN | IP address" "Sets a host to run the administration scripts, can be used multiple times"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-f --file " "Path to file" "Sets a host file to run the administration scripts in each host"
	echo "Components:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-c --component " "component '{component-arguments}'" "Sets the component to run and its arguments"
	printf "\t\t%s%s\n" "Available monitoring components: " "Network, DHCP, SSH, Hardware"	
	echo "Options:"
	printf "\t%s\e[4m%s\e[24m\n\t\t%s\n" "-d --delay " "Seconds" "Sets time in seconds that the script will wait to retrieve the results of the scripts"
	printf "\t%s\n\t\t%s\n" "-m --mail " "Prepares a report and mails it to the Virtualcollaboard mail account"
	echo ""
	echo "Examples:"
	printf "\t%s\n" "$1 -h gestion02 -c Network '{-c -p -l 10}'"
	printf "\t%s\n" "$1 -f servers.txt -c Network '{-c -p -l 10}' -c Logs '{-a}'"
	printf "\t%s\n" "$1 -f servers.txt -c Hardware '{-c -r}' -d 10"
	echo "Note that components' parameters must be enclosed between '{' and '}'"
}

function validateArgumentsData()
{
	if [[ $hosts = "" ]] && [[ ! -f "$hostsFile" ]]; then
		echo "Error: no hosts defined" >&2
		exit 1
	fi

	if [[ -f "$hostsFile" ]]; then
		hosts="$hosts $(cat $hostsFile)"
	fi

	if [[ ${components[Network]} = "" ]] && [[ ${components[DHCP]} = "" ]] && [[ ${components[SSH]} = "" ]] && [[ ${components[Hardware]} = "" ]]; then
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
		elif [[ $component = "DHCP" ]]; then
			realCommand="/home/vadmin/scripts/monitoring/dhcp/dhcp.sh"
		elif [[ $component = "SSH" ]]; then
			realCommand="/home/vadmin/scripts/monitoring/ssh/ssh.sh"
		elif [[ $component = "Hardware" ]]; then
			realCommand="/home/vadmin/scripts/monitoring/cpu-mem/cpu.sh"
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
		echo "Connecting to $host"

		ssh -q -i $IDENTITY_FILE vadmin@$host exit > /dev/null 2>&1
        if [[ $? -eq 255 ]]; then
        	echo "Error: cannot connect to $host, skipping"
        	continue
        fi

		echo "Running commands in $host"
		ssh -i $IDENTITY_FILE vadmin@$host "$commands"
	done
}

function gatherData()
{
	mkdir -p temps
	for host in $hosts;
	do
		mkdir -p temps/$host
		scp -i $IDENTITY_FILE -r vadmin@$host:/home/vadmin/scripts/temps/ ./temps/$host/
		mv ./temps/$host/temps/* ./temps/$host/
		rm -rf ./temps/$host/temps/
	done
}

function generateReport()
{
	local LOGPATH="./temps"
	local mailAddr="virtualcollaboard@gmail.com"
	local files=$(find "./temps" -name *.log)
	local currentDate=$(date)
	currentDate=$(echo $currentDate | sed -r 's/ /_/g')

	enscript -G $files -p "$LOGPATH/Report_$currentDate.ps"
	ps2pdf "$LOGPATH/Report_$currentDate.ps" "$LOGPATH/Report_$currentDate.pdf"

	echo "Virtualcollaboard report attached for commands $commands" | mailx -r "$mailAddr" -a "$LOGPATH/Report_$currentDate.pdf" -s "Report $currentDate" $mailAddr
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

			echo "Waiting $delay seconds for commands to stop"
			sleep $delay

			echo "Copying files from hosts"
			gatherData

			if [[ mail -eq 1 ]]; then
				echo "Generating report and mailing it"
				generateReport
			else
				echo "Done. Logs saved in the ./temps folder"
			fi
		fi
	fi
}

main "$@"