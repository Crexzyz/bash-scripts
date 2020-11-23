#!/bin/bash
SORT=0
TIMES=0
TNUM=3
HELP=0
MAIL=0
DETAILS=0
ABSPATH="." # Testing path (same directory)
#ABSPATH="/home/vadmin/scripts/network" # Production path

function main()
{
	parseArguments "$@"
	rm -f $ABSPATH/log_top.txt $ABSPATH/monitor_report.txt

	local sortType=""
	if [[ $SORT -eq 1 ]]; then
		sortType=-nrk2
	elif [[ $SORT -eq 2 ]]; then
		sortType=-nrk3
	elif [[ $SORT -eq 3 ]]; then
		sortType=-nrk4
	elif [[ $SORT -eq 4 ]]; then
		sortType=-nrk5
	else
		sortType=-nrk1
	fi

	if [[ $HELP -eq 1 ]]; then
		printHelp $0
	elif [[ $MAIL -eq 0 ]] && [[ $DETAILS -eq 0 ]]; then
		hostname
		top -b -d 5 -n 3 >> $ABSPATH/log_top.txt
		printf 'Command stared\n'
		echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM  |" > $ABSPATH/monitor_report.txt
		awk -f $ABSPATH/cpu.awk $ABSPATH/log_top.txt | sort $sortType >> $ABSPATH/monitor_report.txt
		printf 'Command finished\n'
	elif [[ $DETAILS -eq 1 ]]; then
		printf "Process ID\tAVG CPU\t\tDESV STD CPU\t|\tAVG MEM\t\tDESV STD MEM\t|\n"
		top -b -d 5 -n 3 >> $ABSPATH/log_top.txt
		awk -f $ABSPATH/cpu.awk $ABSPATH/log_top.txt | sort $sortType 
	elif [[ $MAIL -eq 1 ]]; then
		isInstalled
		echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM  |" > $ABSPATH/monitor_report.txt
		top -b -d 5 -n 3 >> $ABSPATH/log_top.txt
		awk -f $ABSPATH/cpu.awk $ABSPATH/log_top.txt | sort $sortType >> $ABSPATH/monitor_report.txt
		enscript $ABSPATH/monitor_report.txt -o - | ps2pdf - $ABSPATH/monitor_report.pdf | mail -s "SSH REPORT - VIRTUALCOLLABOARD" -a $ABSPATH/monitor_report.pdf user@mail.com <<< $ABSPATH/monitor_report.txt
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
  	    -t|--times)
	      TIMES=1
		  if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        TNUM=$2
	        shift 2
	      else
	        echo "Error: Missing #" >&2
	        exit 1
	      fi
	      ;;
	    -s|--sort)
		  if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	        SORT=$2
	        shift 2
	      else
	        echo "Error: Missing sort type" >&2
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
	printf "\t%s\n" "-d --details: Show report in terminal"
	printf "\t%s\n" "-m --mail: Send report by mail"
	printf "\t%s\n" "-t --times: Specify # of times ..... "
	printf "\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n" "-s --sort: Sort data by pattern:" "1 - AVG CPU" "2 - DESV STD CPU" "3 - AVG MEM" "4 - DES STD MEM"
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


