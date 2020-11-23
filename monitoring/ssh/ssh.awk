function check(ip, state, connections)
{
	if(state == "ACCEPTED")
		printf("%s ha accedido con éxito %s veces\n", ip,connections)
	else
		printf("ALERTA: Enviar correo porque %s es sospechoso por tener %s intentos fallidos\n", ip,connections)
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