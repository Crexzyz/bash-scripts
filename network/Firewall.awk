function showAll()
{
	if($3 == "udp")
	{
		sourcePort = $8
		destPort = $9
	}
	else
	{
		sourcePort = $9
		destPort = $10
	}

	data = sprintf("%s,%s,%d", substr(destCol, length("dst=") + 1), $3, substr(destPort, length("dport=") + 1))	
}

BEGIN {
	typeIndex = 0
	split(ips, srcIPs, ",")
}
{
	if($3 == "udp")
	{
		sourceCol = $6
		destCol = $7
	}
	else
	{
		sourceCol = $7
		destCol = $8
	}

	srcIP = substr(sourceCol, length("src=") + 1)
	

	skip = 1;
	for( i = 1; i <= length(srcIPs); ++i)
	{
		if(srcIP == srcIPs[i])
			skip = 0
	}

	if(skip == 1)
		next

	showAll()

	if(connections[data] == "")
	{
		typeData[typeIndex] = data;
		connections[data] = 1
		++typeIndex
	}
	else
	{
		++connections[data]
	}

	# connections["192.168.13.1,tcp,80"]
}

END {
		for(i = 0; i < typeIndex; ++i)
		{
			split(typeData[i], resArr, ",")
			printf("%s\t\t  %s\t\t%d\t  %d\n", resArr[1], resArr[2], resArr[3], connections[typeData[i]])
		}

}