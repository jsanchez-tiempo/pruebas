function modulo(u, v)
{
    return sqrt(u*u+v*v);
}

NR==1{

    array[NR-1]["x"]=$1;
    array[NR-1]["y"]=$2;
    array[NR-1]["valor"]=$3;
	cont=1;
	print $1,$2,$3;
}
NR>1{
#    UMBRAL=umbral
    for(i=0; i<cont; i++){
        #print cont" "i": "$4,array[i]["x"],$5,array[i]["y"], modulo($4-array[i]["x"],$5-array[i]["y"]);
        if(modulo($1-array[i]["x"],$2-array[i]["y"]) < umbral)
            break;

    }
    if(i==cont){
        array[cont]["x"]=$1;
        array[cont]["y"]=$2;
        array[cont]["valor"]=$3;

	    print $1,$2,$3;
        cont++;
    }



}
