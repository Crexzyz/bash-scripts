function isInteger(x) {
 	return (x ~ /^[-+]?[0-9]+$/) 
}

function startsWith(text, target)
{
	len = length(target)
	textSub = substr(text, 1, len)
	return (textSub == target)
}