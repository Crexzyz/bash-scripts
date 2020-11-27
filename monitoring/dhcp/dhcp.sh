#!/bin/bash
MAIL=0
DETAILS=0
HELP=0
ADDRESS=""
LOGPATH="." # Testing path (same directory)
#LOGPATH=/home/vadmin/scripts/temps
ABSPATH="." # Testing path (same directory)
#ABSPATH="/home/vadmin/scripts/network" # Production path

function main()
{
	parseArguments "$@"
	if [[ $# -eq 0 ]]; then
		printf 'Command ran\n'
		echo '    Date                MAC Address             Host            IP Address      State' > dhcp_report.txt
		journalctl -u dhcpd -n 500 --no-pager > $LOGPATH/log_dhcp.txt
		awk -f $ABSPATH/dhcp.awk $LOGPATH/log_dhcp.txt >> $LOGPATH/dhcp_report.txt
	fi

	if [[ $HELP -eq 1 ]]; then
		printHelp $0
	fi

	if [[ $DETAILS -eq 1 ]]; then
		hostname
		printf '\tDate\t\tMAC Address\t\tHost\t\tIP Address\tState\n'
		journalctl -u dhcpd -n 500 --no-pager > $LOGPATH/log_dhcp.txt
		awk -f $ABSPATH/dhcp.awk $LOGPATH/log_dhcp.txt
	fi

	if [[ $MAIL -eq 1 ]]; then
		isInstalled
		journalctl -u dhcpd -n 500 --no-pager > $LOGPATH/log_dhcp.txt
		awk -f $ABSPATH/dhcp.awk $LOGPATH/log_dhcp.txt >> $LOGPATH/dhcp_report.txt
		enscript $LOGPATH/dhcp_report.txt -o - | ps2pdf - $LOGPATH/dhcp_report.pdf  | mailx -r "$mailAddr" -s "DHCP REPORT - VIRTUALCOLLABOARD" -a $ABSPATH/dhcp_report.pdf $ADDRESS <<< $ABSPATH/dhcp_report.txt
		printf 'Mail sent - PENDIENTE\n'
	fi
}

function parseArguments()
{
	while (( "$#" )); do
	  case "$1" in
	    -m|--mail)
	      MAIL=1
	      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        ADDRESS=$2
	        shift 2
	      else
	        echo "Error: Missing #" >&2
	        exit 1
	      fi
	      ;;
  	    -d|--details)
	      DETAILS=1
	      shift
	      ;;
  	    -h|--help)
	      HELP=1
	      shift
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
	printf "\t%s\n" "-d --details: Show report in terminal"
}


function isInstalled {
  if yum list installed ghostscript >/dev/null 2>&1; then
    if yum list installed enscript >/dev/null 2>&1; then
        true
     else
	yum install enscript -y
     fi
  else
      	yum install ghostscript -y
        yum install enscript -y
  fi
}


# Pass arguments as-is
main "$@"
