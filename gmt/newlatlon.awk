function wind_ff(u, v)
{
	return sqrt ( u * u + v * v );
}
BEGIN{
	r_earth=6357000;
	pi=3.1416;
}
{
	dx=$3;
	dy=$4;
	dlat=scale*(dy/r_earth)*(180/pi);
	newlat=$2+dlat
	if(newlat>90)
		newlat=180-newlat;
	else if (newlat<-90)
		newlat=-180-newlat;

	dlon=scale*(dx/r_earth)*(180/pi)/(cos(dy*pi/180));
	print $1,$2,$1+dlon,newlat,wind_ff($3,$4)*3.6
}
