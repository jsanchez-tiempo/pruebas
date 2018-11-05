function existecodigo(codigos,codcont,valor){
	for(i=0;i<codcont;i++)
		if(codigos[i]==valor)
			return 1;
	return 0;
	
}
function copiarregistro(reg1, reg2){
	reg2["fecha"]=reg1["fecha"];
	reg2["lon"]=reg1["lon"];
	reg2["lat"]=reg1["lat"];
	reg2["x"]=reg1["x"];
	reg2["y"]=reg1["y"];
	reg2["pres"]=reg1["pres"];
	reg2["tipo"]=reg1["tipo"];
}

NR==1{	
# N=3; #Debe ser impar
 n=(N-1)/2

 fanterior=$1
 valorNAN=-200
 cont=0;
 array[$8][cont]["fecha"]=$1;
 array[$8][cont]["lon"]=$2;
 array[$8][cont]["lat"]=$3;
 array[$8][cont]["x"]=$4;
 array[$8][cont]["y"]=$5;
 array[$8][cont]["pres"]=$6;
 array[$8][cont]["tipo"]=$7;
 codigos[0]=$8
 codcont=1;
}

NR>1{
 if(existecodigo(codigos,codcont,$8)==0){
	 codigos[codcont]=$8
	 codcont++;
 }
 if($1>fanterior){
	 cont++;
	 fanterior=$1;
 }

 array[$8][cont]["fecha"]=$1;
 array[$8][cont]["lon"]=$2;
 array[$8][cont]["lat"]=$3;
 array[$8][cont]["x"]=$4;
 array[$8][cont]["y"]=$5;
 array[$8][cont]["pres"]=$6;
 array[$8][cont]["tipo"]=$7;

}
END{
#	print codcont,cont 
	for(i=0;i<codcont;i++){
		cod=codigos[i];
		for(j=0;j<=cont;j++){
			acumX=0;
			acumY=0;
#			contvalidos=0;
			if(array[cod][j]["fecha"]!=0){
				for(z=j-n;z<=j+n;z++){
					acumX+=array[cod][z]["lon"];
					acumY+=array[cod][z]["lat"];
#					print array[cod][z]["fecha"],cod;
					if(array[cod][z]["fecha"]==0){
						acumX=array[cod][j]["lon"]*N;
						acumY=array[cod][j]["lat"]*N;				
#						print "salio ",array[cod][z]["fecha"];
						break;
					}

				}
				#fade=1
				fadein=1
				fadeout=1
				indexminfecha=j-nf;
				for(z=j; z>=j-nf+1; z--)
					if(array[cod][z]["fecha"]==minfecha)
						indexminfecha=z;
					else if(array[cod][z]["fecha"]==0)
						break;


				if(z>=indexminfecha)
					fadein=(j-z)/nf;

				#print indexminfecha,z,j, fadein

                indexmaxfecha=j+nf+1
				for(z=j; z<j+nf; z++)
					if(array[cod][z]["fecha"]==maxfecha)
						indexmaxfecha=z;
					else if(array[cod][z]["fecha"]==0 )
						break;

#				for(z=j; z<j+nf; z++)
#					if(array[cod][z]["fecha"]==maxfecha )
#						break;

				if(z<=indexmaxfecha)
					fadeout=(z-j)/nf;

				fade=(fadein<fadeout)?fadein:fadeout;


				printf "%s %.8f %.8f %s %s %s %s %s %.4f\n",array[cod][j]["fecha"],acumX/N,acumY/N,array[cod][j]["x"],array[cod][j]["y"],array[cod][j]["pres"],array[cod][j]["tipo"],cod,fade;
			}	
		}
			
	}

}
