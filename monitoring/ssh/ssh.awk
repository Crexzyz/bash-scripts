function check(ip, state, connections)
{
	if(state == "ACCEPTED")
		printf("%s ha accedido con éxito %s veces\n", ip,connections)
	else
	{
		system("cat /etc/hostname > report_temp.txt")
		system("echo \"ALERTA: Se ha detectado intentos ssh sospechosos en el host\" >> report_temp.txt")
	    system("cat  \"report_temp.txt\" | mailx -v -r \"virtualcollaboard@gmail.com\" -s \"SSH ALERT - VIRTUALCOLLABOARD\" virtualcollaboard@gmail.com")	}
}

BEGIN {
       	typeIndex = 0
}
{
	if ( NR>1)
	{
		if($6 == "Accepted")
		{
			srcIP = $11
			state = "ACCEPTED"
		}
		else if ($6 == "error:" )
		{
			srcIP = $13
			state = "FAILURE"
		}
		else
		{
			next
		}

		date = $1" "$2" "$3
		printf("%s\t\t%s\t%s\n", date,srcIP,state)


		data = sprintf("%s,%s", srcIP,state)

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
}

END {
	for(i = 0; i < typeIndex; ++i)
	{
		split(typeData[i], resArr, ",")
		if (connections[typeData[i]] > 1)
		{
			check(resArr[1], resArr[2], connections[typeData[i]])
		}
	}
}