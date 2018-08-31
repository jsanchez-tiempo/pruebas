function max(a,b)
{
	return 	(a < b) ? b : a;
}
function min(a,b)
{
	return 	(a > b) ? b : a;
}
{
	R=$1/255;	
	G=$2/255;	
	B=$3/255;	

	Cmax=max(max(R,G),B);
	Cmin=min(min(R,G),B);

	diff=Cmax -Cmin;

	#Pintamos H
	if(diff==0)
		h=0;
	else if(Cmax==R)
		h=(((G-B)/diff)%6)*60;
	else if(Cmax==G)
		h=(((B-R)/diff)+2)*60;
	else if(Cmax==B)
		h=(((R-G)/diff)+4)*60;

	if(h<0)
		h+=360;

	printf "%d ",h;

	#Pintamos S
	if(Cmax==0)
		printf "0 ";
	else
		printf "%d ",diff/Cmax*100;

	#Pintamos V
	printf "%d\n",Cmax*100;

}
