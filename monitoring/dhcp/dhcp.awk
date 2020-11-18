BEGIN {
       	typeIndex = 0
}
{
        if ( NR>1)
        {
                if($6 == "DHCPACK")
                {
                        srcIP = $8
                        srcMAC = $10
                        host = $11
                        if(host == "via")
                                host = "\t"
                        state = "LOAD"
                }
                else if ($6 == "Remove" )
                {
                        srcIP = $12
                        host = $9
                        state = "EXPIRATION"
                }
                else
                {
                        next
                }

                date = $1" "$2" "$3
                if(state == "LOAD")
                        printf("%s\t\t%s\t%s\t%s\t%s\n",date,srcMAC,host,srcIP,state)
                else
                    	printf("%s\t\t\t\t\t\t\t%s\t%s\n",date,srcIP,state)
        }
}

END {
}


