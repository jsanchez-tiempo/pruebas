{
	H=$1%360;	
	S=$2/100;	
	V=$3/100;

	C=V*S;
	X=C*(1-sqrt(((H/60)%2-1)^2));
	m=V-C;


	if(H<60){
		R=C;
		G=X;
		B=0;
	}else if(H>=60 && H <120){
		R=X;
		G=C;
		B=0;
	}else if(H>=120 && H < 180){
		R=0;
		G=C;
		B=X;
	}else if(H>=180 && H < 240){
		R=0;
		G=X;
		B=C;
	}else if(H>=240 && H < 300){
		R=X;
		G=0;
		B=C;
	}
	else if(H>=300 && H < 360){
		R=C;
		G=0;
		B=X
	}
	
	printf "%d %d %d\n",(R+m)*255,(G+m)*255,(B+m)*255;


}
