NR==1{
	print $1,$2,$3,$2
}
NR==2{
	pa=$1; 
	pb=$3; 
	preva=$2;
	prevb=$4
}
NR>2{
	split(preva,a,"/"); 
	split(prevb,b,"/"); 
	color=(a[1]+b[1])/2"/"(a[2]+b[2])/2"/"(a[3]+b[3])/2;
	print pa,color,pb,color; 
	preva=$2; 
	prevb=$4; 
	pa=$1; 
	pb=$3
}
END{
	print $1,$4,$3,$4
}
