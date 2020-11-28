#!/bin/bash
SORT=0
TIMES=0
TNUM=3
HELP=0
MAIL=0
DISK=0
AUTO=0
ADDRESS=""
DETAILS=0
#LOGPATH="." # Testing path (same directory)
LOGPATH=/home/vadmin/scripts/temps
# ABSPATH="." # Testing path (same directory)
ABSPATH="/home/vadmin/scripts/monitoring/cpu-mem" # Production path

function main()
{
	parseArguments "$@"
	rm -f $LOGPATH/log_top.txt $LOGPATH/monitor_report.log $LOGPATH/iotop_report.log

	local sortType=""
	if [[ $SORT -eq 1 ]]; then
		sortType=-nrk1
	elif [[ $SORT -eq 2 ]]; then
		sortType=-nrk2
	elif [[ $SORT -eq 3 ]]; then
		sortType=-nrk3
	elif [[ $SORT -eq 4 ]]; then
		sortType=-nrk4
	elif [[ $SORT -eq 5 ]]; then
		sortType=-nrk5
	elif [[ $SORT -eq 6 ]]; then
		sortType=-nrk6
	elif [[ $SORT -eq 7 ]]; then
		sortType=-nrk7
	fi

	if [[ $HELP -eq 1 ]]; then
		printHelp $0
	elif [[ $MAIL -eq 0 ]] && [[ $DETAILS -eq 0 ]] && [[ $DISK -eq 0 ]]; then
		hostname
		top -b -d 5 -n 2 >> $LOGPATH/log_top.txt
		if [[ $AUTO -eq 0 ]]; then
			printf 'Command started\n'
		fi
		echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM" > $LOGPATH/monitor_report.log
		awk -f $ABSPATH/cpu.awk $LOGPATH/log_top.txt | sort $sortType >> $LOGPATH/monitor_report.log

		if [[ $AUTO -eq 0 ]]; then
			printf 'Command finished\n'
		fi
	elif [[ $DETAILS -eq 1 ]]; then
		if [[ $DISK -eq 1 ]] ; then
			if [[ $MAIL -eq 1 ]]; then
				isInstalled
		        printf "Process ID\tAVG READ\tDESV STD READ\t|\tAVG WRITE\tDESV STD WRITE\t|\tAVG IO\t\tDESV STD IO\n"
		        printf "Process ID\tAVG READ\tDESV STD READ\t|\tAVG WRITE\tDESV STD WRITE\t|\tAVG IO\t\tDESV STD IO\n" > $LOGPATH/iotop_report.log
				iotop -b -d 5 -n 3 >> $LOGPATH/log_iotop.txt
				awk -f $ABSPATH/disk.awk $LOGPATH/log_iotop.txt | sort $sortType >> $LOGPATH/iotop_report.log
				cat $LOGPATH/iotop_report.log
				enscript $LOGPATH/iotop_report.log -o - | ps2pdf - $LOGPATH/iotop_report.pdf 
				cat $LOGPATH/iotop_report.log | mailx -v -r "virtualcollaboard@gmail.com" -s "DISK REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/monitor_report.pdf $ADDRESS
				printf 'Mail sent to %s\n' $ADDRESS
			else
		        printf "Process ID\tAVG READ\tDESV STD READ\t|\tAVG WRITE\tDESV STD WRITE\t|\tAVG IO\t\tDESV STD IO\n"
				iotop -b -d 5 -n 3 > $LOGPATH/log_iotop.txt
				awk -f $ABSPATH/disk.awk $LOGPATH/log_iotop.txt | sort $sortType
			fi
		else
			if [[ $MAIL -eq 1 ]]; then
				isInstalled
				echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM"
				echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM" > $LOGPATH/monitor_report.log
				top -b -d 5 -n 3 >> $LOGPATH/log_top.txt
				awk -f $ABSPATH/cpu.awk $LOGPATH/log_top.txt | sort $sortType >> $LOGPATH/monitor_report.log
				cat $LOGPATH/monitor_report.log
				enscript $LOGPATH/monitor_report.log -o - | ps2pdf - $LOGPATH/monitor_report.pdf 
				cat $LOGPATH/monitor_report.log | mailx -v -r "virtualcollaboard@gmail.com" -s "CPU-MEM REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/monitor_report.pdf $ADDRESS
				printf 'Mail sent to %s\n' $ADDRESS
			else
				printf "Process ID\tAVG CPU\t\tDESV STD CPU\t|\tAVG MEM\t\tDESV STD MEM\n"
				top -b -d 5 -n 3 > $LOGPATH/log_top.txt
				awk -f $ABSPATH/cpu.awk $LOGPATH/log_top.txt | sort $sortType 
			fi
		fi
	elif [[ $DISK -eq 1 ]]; then
        printf "Process ID\tAVG READ\tDESV STD READ\t|\tAVG WRITE\tDESV STD WRITE\t|\tAVG IO\t\tDESV STD IO\n" > $LOGPATH/iotop_report.log
		iotop -b -d 5 -n 3 >> $LOGPATH/log_iotop.txt
		awk -f $ABSPATH/disk.awk $LOGPATH/log_iotop.txt | sort $sortType >> $LOGPATH/iotop_report.log
	elif [[ $MAIL -eq 1 ]]; then
		isInstalled
		if [[ $DISK -eq 1 ]] ; then
	        printf "Process ID\tAVG READ\tDESV STD READ\t|\tAVG WRITE\tDESV STD WRITE\t|\tAVG IO\t\tDESV STD IO\n" > $LOGPATH/iotop_report.log
			iotop -b -d 5 -n 3 >> $LOGPATH/log_iotop.txt
			awk -f $ABSPATH/disk.awk $LOGPATH/log_iotop.txt | sort $sortType >> $LOGPATH/iotop_report.log
			enscript $LOGPATH/iotop_report.log -o - | ps2pdf - $LOGPATH/iotop_report.pdf 
			cat $LOGPATH/iotop_report.log | mailx -v -r "virtualcollaboard@gmail.com" -s "DISK REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/monitor_report.pdf $ADDRESS
			printf 'Mail sent to %s\n' $ADDRESS
		else
			echo "Process ID     AVG CPU       DESV STD CPU       |       AVG MEM           DESV STD MEM" > $LOGPATH/monitor_report.log
			top -b -d 5 -n 3 >> $LOGPATH/log_top.txt
			awk -f $ABSPATH/cpu.awk $LOGPATH/log_top.txt | sort $sortType >> $LOGPATH/monitor_report.log
			enscript $LOGPATH/monitor_report.log -o - | ps2pdf - $LOGPATH/monitor_report.pdf 
			cat $LOGPATH/monitor_report.log | mailx -v -r "virtualcollaboard@gmail.com" -s "CPU-MEM REPORT - VIRTUALCOLLABOARD" -a $LOGPATH/monitor_report.pdf $ADDRESS
			printf 'Mail sent to %s\n' $ADDRESS
		fi
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
  	    --disk)
	      DISK=1
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
	printf "\t%s\n" "--disk: Report about disk "
	printf "\t%s\n" "-t --times: Specify # of times ..... "
	printf "\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n" "-s --sort: Sort data by pattern: " "1 - PROCESS ID" "2 - AVG CPU" "3 - DESV STD CPU" "4 - AVG MEM" "5 - DES STD MEM" "6 - AVG MEM" "7 - DES STD MEM"
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
