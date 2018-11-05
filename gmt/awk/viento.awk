function wind_ff(u, v)
{
	return sqrt ( u * u + v * v );
}

function wind_dd (u, v){

	PI=3.14159265358979323846;
	RAD2GRA=180/PI;
	x = atan2 ( -u, -v ) * RAD2GRA;
	if ( x < 0.0 )
		x += 360.0;
	return x;
}

{	
	print $1,$2,wind_ff($3,$4),wind_dd($3,$4);
}
