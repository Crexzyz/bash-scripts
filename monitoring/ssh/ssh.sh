#!/bin/bash
MAIL=0
AUTO=0
DETAILS=0
HELP=0
ADDRESS=""
# LOGPATH="." # Testing path (same directory)
LOGPATH=/home/vadmin/scripts/temps
# ABSPATH="." # Testing path (same directory)
ABSPATH="/home/vadmin/scripts/monitoring/ssh" # Production path

function main()
{
	parseArguments "$@"

	if [[ -f $LOGPATH/ssh_report.log ]]; then
		echo "" > $LOGPATH/ssh_report.log
	fi

	if [[ $# -eq 0 ]] || [[ $AUTO -eq 1 ]]; then
		if [[ $AUTO -eq 0 ]]; then
			hostname
			printf 'Command ran\n'
		fi

		journalctl _SYSTEMD_UNIT=sshd.service > $LOGPATH/log_ssh.txt
		echo '    Date                 Address        State' > $LOGPATH/ssh_report.log
		awk -f $ABSPATH/ssh.awk $LOGPATH/log_ssh.txt >> $LOGPATH/ssh_report.log
	fi

	if [[ $HELP -eq 1 ]]; then
		printHelp $0
	fi

	journalctl _SYSTEMD_UNIT=sshd.service > $LOGPATH/log_ssh.txt
	
	if [[ $DETAILS -eq 1 ]]; then
		printf '\tDate\t\tAddress\t\tState\n'
		awk -f $ABSPATH/ssh.awk $LOGPATH/log_ssh.txt
	fi

	if [[ $MAIL -eq 1 ]]; then
		isInstalled
		echo '    Date                 Address        State' > $LOGPATH/ssh_report.log
		journalctl _SYSTEMD_UNIT=sshd.service > $LOGPATH/log_ssh.txt
		awk -f $ABSPATH/ssh.awk $LOGPATH/log_ssh.txt >> $LOGPATH/ssh_report.log
		enscript $LOGPATH/ssh_report.log -o - | ps2pdf - $LOGPATH/ssh_report.pdf 
		cat $LOGPATH/ssh_report.log | mailx -v -r "virtualcollaboard@gmail.com" -s "SSH REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/ssh_report.pdf $ADDRESS
		printf 'Mail sent to %s\n' $ADDRESS
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
	        echo "Error: Missing mail address" >&2
	        exit 1
	      fi
	      ;;
  	    -d|--details)
	      DETAILS=1
	      shift
	      ;;
  	    -a|--auto)
	      AUTO=1
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
	printf "\t%s\n" "-d --details: Show report in terminal"
	printf "\t%s\n" "-m --mail: Send report by mail"
}

function isInstalled 
{
	if yum list installed ghostscript >/dev/null 2>&1; then
		if yum list installed enscript >/dev/null 2>&1; then
			if yum list installed mailx >/dev/null 2>&1; then
			    true
			else
				yum -y install mailx 
			fi
		else
			yum install enscript -y
		fi
	else
	  	yum install ghostscript -y
	    yum install enscript -y
		yum -y install mailx 
	fi
}

# Pass arguments as-is
main "$@"
