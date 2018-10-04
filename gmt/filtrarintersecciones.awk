function intersecta(x1,y1,x2,y2,w,h){
	#print x1,y1,x2,y2,((x2<x1+w && x2>=x1) || (y2<y1+h && y2>=y1) || (x1<x2+w && x1>=x2) || (y1<y2+h && y1>=y2))
	return x2<x1+w && x2>=x1 && y2<y1+h && y2>=y1 || x1<x2+w && x1>=x2 && y1<y2+h && y1>=y2 || \
	x2<x1+w && x2>=x1 && y1<y2+h && y1>=y2 || x1<x2+w && x1>=x2 && y2<y1+h && y2>=y1;
}
BEGIN{
	w=114/xsize*xlength;
	h=65/ysize*ylength;
	#print w,h;
	count=0;
}
NR==1{
    #print "x:"$1" y:"$2;

	puntos[count]["x"]=$1; 
	puntos[count]["y"]=$2; 
	puntos[count]["valor"]=$3; 
	count++
}
NR>1{
	x=$1;
	y=$2;
	#print "x:"x" y:"y;
	valor=$3;
	interseccion=false;
	for(i=0; i<count && !interseccion; i++){

		interseccion=interseccion||intersecta(x,y,puntos[i]["x"],puntos[i]["y"],w,h);
	#	print puntos[i]["x"],puntos[i]["y"],interseccion;
	}
	if(!interseccion){
		puntos[count]["x"]=$1; 
		puntos[count]["y"]=$2; 
		puntos[count]["valor"]=$3;
		count++;
	}
}
END{
	for(i=0; i<count; i++)
		print puntos[i]["x"],puntos[i]["y"],puntos[i]["valor"]
}
