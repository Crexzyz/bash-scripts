function isInteger(x) {
        return (x ~ /^[-+]?[0-9]+$/)
}

function abs(v)
{
	return v < 0 ? -v : v
}

BEGIN {
        FS=" "; RS="\n";
	index1 = 0
	index2 = 0
	flag = 0
}
{
	if ( isInteger($1) )
	{
		PID = $1
		CPU = $9
		MEM = $10

		if( PIDs[PID] == "" )
		{
			PIDs[PID] = PID
		}

		CPUs[PID][index2] = CPU
		MEMs[PID][index2] = MEM
	}
	else
	{
		++flag
		if (flag == 7)
		{
			++index2
			flag = 0
		}
	}

}
END {
	promCPU  = 0
	promMEM  = 0
	sumCPU = 0
	sumMEM = 0

	generalCount = 0
	allPromCPU = 0
	allPromMEM = 0

	for (i in PIDs)
    {
        for(j in CPUs[i])
        {
			promCPU += CPUs[i][j]
			promMEM += MEMs[i][j]

			generalCount += 1
			allPromCPU += CPUs[i][j]
			allPromMEM += MEMs[i][j]
        }

		promCPU = promCPU / length(CPUs[i])
		promMEM = promMEM / length(MEMs[i])

		for(j in CPUs[i])
		{
			sumCPU += abs(CPUs[i][j]-promCPU)**2
			sumMEM += abs(CPUs[i][j]-promMEM)**2
		}

        sumCPU /= length(CPUs[i])
		sumMEM /= length(MEMs[i])

		devCPU = sqrt(sumCPU)
		devMEM = sqrt(sumMEM)

		printf("%s\t\t%0.03f\t\t%0.03f\t\t|\t%0.03f\t\t%0.03f\n", PIDs[i], promCPU, devCPU, promMEM, devMEM)
    }

    allPromMEM = allPromMEM / generalCount
    allPromCPU = allPromCPU / generalCount
    allDevCPU = 0
	allDevMEM = 0

    for(process in PIDs)
    {
    	for(thread in CPUs[process])
    	{
    		allDevMEM += abs(CPUs[process][thread] - allPromMEM)**2
    		allDevCPU += abs(CPUs[process][thread] - allPromCPU)**2
    	}
    }

    allDevMEM = sqrt(allDevMEM / generalCount)
    allDevCPU = sqrt(allDevCPU / generalCount)

    printf("%s\t\t%0.03f\t\t%0.03f\t\t|\t%0.03f\t\t%0.03f\n", "General", allPromCPU, allDevCPU, allPromMEM, allDevMEM)
}
