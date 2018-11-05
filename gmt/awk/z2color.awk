NR==FNR{
	if($1=="B"){
		bcolor=$2;
	}
	else if($1=="F"){
		fcolor=$2;
	}
	else if($1!="N"){
		colores[NR-1]["min"]=$1;
		colores[NR-1]["minvalue"]=$2;
		colores[NR-1]["max"]=$3;
		colores[NR-1]["maxvalue"]=$4;
	}
}
NR!=FNR{
	zvalue=$5
#	ultimo=length(colores)-1;

#	print zvalue,ultimo,colores[ultimo]["max"];
	if(zvalue<colores[0]["min"]){
		
		split(bcolor,color,"/");
		print color[1],color[2],color[3];
	
	}
	else if(zvalue>=colores[length(colores)-1]["max"]){
		split(fcolor,color,"/");
		print color[1],color[2],color[3];
	}
	else
		for(i=0; i<length(colores); i++){
			if(zvalue >= colores[i]["min"] && zvalue < colores[i]["max"]){
				weight=1-(zvalue-colores[i]["min"])/(colores[i]["max"]-colores[i]["min"]);
				split(colores[i]["minvalue"],mincolor,"/");
				split(colores[i]["maxvalue"],maxcolor,"/");
				print mincolor[1]*weight + maxcolor[1]*(1-weight),mincolor[2]*weight + maxcolor[2]*(1-weight),mincolor[3]*weight + maxcolor[3]*(1-weight);
				break;
			}
		}
}
