#!/bin/bash
MAIL=0
DETAILS=0
HELP=0
LOGPATH="." # Testing path (same directory)
#LOGPATH=/home/vadmin/scripts/temps
ABSPATH="." # Testing path (same directory)
#ABSPATH="/home/vadmin/scripts/network" # Production path

function main()
{
	parseArguments "$@"
	if [[ $# -eq 0 ]]; then
		hostname
		printf 'Command ran\n'
		journalctl _SYSTEMD_UNIT=sshd.service > $LOGPATH/log_ssh.txt
		echo '    Date                 Address        State' > $LOGPATH/ssh_report.txt
		awk -f $ABSPATH/ssh.awk $LOGPATH/log_ssh.txt >> $LOGPATH/ssh_report.txt
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
		echo '    Date                 Address        State' > $LOGPATH/ssh_report.txt
		journalctl _SYSTEMD_UNIT=sshd.service > $LOGPATH/log_ssh.txt
		awk -f $ABSPATH/ssh.awk $LOGPATH/log_ssh.txt >> $LOGPATH/ssh_report.txt
		enscript $LOGPATH/ssh_report.txt -o - | ps2pdf - $LOGPATH/ssh_report.pdf | mail -s "SSH REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/ssh_report.pdf user@mail.com <<< $LOGPATH/ssh_report.txt
		printf 'Mail sent - PENDIENTE\n'
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
