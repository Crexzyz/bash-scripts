#!/bin/bash
SORT=0
function main()
{
        rm -f top.txt out.txt
        top -b -d 5 -n 3 >> top.txt
        printf "Process ID\tAVG CPU\t\tDESV STD CPU\t|\tAVG MEM\t\tDESV STD MEM\t|\n"
        awk -f CPU.awk top.txt | sort -nk1
}


# Pass arguments as-is
main "$@"


