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

	data = sprintf("%s,%s,%d", substr(sourceCol, length("src=") + 1), $3, substr(destPort, length("dport=") + 1))	
}

BEGIN {
	typeIndex = 0
	split(ips, dstIPs, ",")
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

	dstIP = substr(destCol, length("src=") + 1)
	

	skip = 1;
	for( i = 1; i <= length(dstIPs); ++i)
	{
		if(dstIP == dstIPs[i])
			skip = 0
	}

	if(skip == 1)
		next

	if(type == "P" || type == "D")
		showAll()
	else
		data = substr(sourceCol, length("dst=") + 1)

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
}

END {
	if(type == "P")
	{
		for(i = 0; i < typeIndex; ++i)
		{
			split(typeData[i], resArr, ",")
			printf("%s\t%s\t\t%d\t%d\n", resArr[1], resArr[2], resArr[3], connections[typeData[i]])
		}
	}
	else if(type == "D")
	{
		for(i = 0; i < typeIndex; ++i)
		{
			split(typeData[i], resArr, ",")
			printf("%s\t\t%s\t\t%d\t%d\n", resArr[1], resArr[2], resArr[3], connections[typeData[i]])
		}
	}
	else
	{
		for(i = 0; i < typeIndex; ++i)
			printf("%s\t%d\n", typeData[i], connections[typeData[i]])
	}

}