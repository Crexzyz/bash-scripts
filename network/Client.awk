BEGIN {
	typeIndex = 0

	# Type P == Ports

	if(type == "P")
	{
		targetPrefix = "dport="
		offsetPrefix = "sport="
	}
	else
	{
		targetPrefix = "dst="
		offsetPrefix = "src="	
	}
}

{
	if(type == "P")
	{
		offsetCol = $10
		targetCol = $9
	}
	else
	{
		offsetCol = $8
		targetCol = $7	
	}


	if(startsWith(targetCol, offsetPrefix))
		data = substr(offsetCol, length(targetPrefix) + 1)
	else
		data = substr(targetCol, length(targetPrefix) + 1)
    
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
	{
		printf("%s\t%d\n", typeData[i], connections[typeData[i]], connections[typeData[i]] != 1 ? "s" : "")
	}
}