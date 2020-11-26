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
	if ( isInteger($2) )
	{
		PID = $2
		DREAD = $5
		DWRITE = $7
		DIO= $11

		if( PIDs[PID] == "" )
		{
			PIDs[PID] = PID
#			printf("Meto en pid: %s \n=======================\n", PID)

		}

		DREADs[PID][index2] = DREAD
#		printf("Meto [%d][%d] en cpu: %s \n", PID, index2, DREAD)
		DWRITEs[PID][index2] = DWRITE
#		printf("Meto [%d][%d] en mem: %s \n", PID, index2, DWRITE)
		DIOs[PID][index2] = DIO

	}
	else
	{
		++flag
		if (flag == 3)
		{
			++index2
			flag = 0
		}
	}

}
END {
	promCPU  = 0
	promMEM  = 0
	promIO  = 0
	sumCPU = 0
	sumMEM = 0
	sumIO = 0
	for (i in PIDs)
        {
            for(j in DREADs[i])
            {
				promCPU += DREADs[i][j]
				promMEM += DWRITEs[i][j]
				promIO += DIOs[i][j]
#               printf(" %s      ",CPUs[i][j]) 
            }

			promCPU = promCPU / length(DREADs[i])
			promMEM = promMEM / length(DWRITEs[i])
			promIO = promIO / length(DIOs[i])
			
			for(j in DREADs[i])
			{
				sumCPU += abs(DREADs[i][j]-promCPU)**2
				sumMEM += abs(DWRITEs[i][j]-promMEM)**2
				sumIO += abs(DIOs[i][j]-promIO)**2
			}

		    sumCPU /= length(DREADs[i])
			sumMEM /= length(DWRITEs[i])
			sumIO /= length(DIOs[i])

			devCPU = sqrt(sumCPU)
			devMEM = sqrt(sumMEM)
			devIO = sqrt(sumIO)

			printf("%s\t\t%0.03f\t\t%0.03f\t\t|\t%0.03f\t\t%0.03f\t\t|\t%0.03f\t\t%0.03f\t\t|\n", PIDs[i], promCPU, devCPU, devIO, promMEM, devMEM, promIO)
        }
}