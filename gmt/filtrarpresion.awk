function modulo(u, v)
{
    return sqrt(u*u+v*v);
}
NR==1{
	finicial=$1;
	cont=1;
}
$1==finicial{
    array[NR-1]["cod"]=NR;
    array[NR-1]["fecha"]=$1;
    array[NR-1]["lon"]=$2;
    array[NR-1]["lat"]=$3;
    array[NR-1]["x"]=$4;
    array[NR-1]["y"]=$5;
    array[NR-1]["pres"]=$6;
    array[NR-1]["tipo"]=$7;
	print $0,NR;
	cont++;
}
$1>finicial{
   "date -u -d \""substr($1,0,8)" "substr($1,9,4)"\" +%Y%m%d%H%M" | getline fecha; 
   "date -u -d \""substr($1,0,8)" "substr($1,9,4)" -"mins" mins\" +%Y%m%d%H%M" | getline fechaanterior;

    UMBRAL=umbral
    for(i=0; i<cont; i++){
	
        if(modulo($4-array[i]["x"],$5-array[i]["y"]) < UMBRAL && fechaanterior==array[i]["fecha"] ){
		#print array[i]["fecha"], fechaanterior;
            print $0,array[i]["cod"];
            array[i]["x"]=$4;
            array[i]["y"]=$5;
	    array[i]["fecha"]=fecha;
            break;
        }
    }
    if(i==cont){

        array[cont]["cod"]=cont;
        array[cont]["fecha"]=$1;
        array[cont]["lon"]=$2;
        array[cont]["lat"]=$3;
        array[cont]["x"]=$4;
        array[cont]["y"]=$5;
        array[cont]["pres"]=$6;
        array[cont]["tipo"]=$7;

        print $0,cont;
        cont++;
    }



}


