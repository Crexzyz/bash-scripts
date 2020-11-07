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

	for(i = 0; i < typeIndex; ++i)
		printf("%s\t%d\n", typeData[i], connections[typeData[i]])
}