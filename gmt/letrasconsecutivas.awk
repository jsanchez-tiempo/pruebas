{
 "date -u -d \""substr($1,0,8)" "substr($1,9,4)"\" +%Y%m%d%H%M" | getline fecha; 
 "date -u -d \""substr($1,0,8)" "substr($1,9,4)" -"mins" mins\" +%Y%m%d%H%M" | getline fechaanterior;


 if(fechas[$8]["fecha"]!=fechaanterior){
	#if(countmax[$8]<count[$8])
	#	countmax[$8]=count[$8];
	if(count[$8]>=n)
		print acum[$8];
	count[$8]=0;
	acum[$8]="";
 }
 count[$8]++;
 fechas[$8]["fecha"]=fecha;
 if(acum[$8]=="")
	acum[$8]=$0;
 else
	acum[$8]=acum[$8]"\n"$0;
}
END{
# for(i=1;count[i]>0;i++)
#	print i,(count[i]>countmax[$8])?count[i]:countmax[$8];
 for(i=1;count[i]>0;i++)
	if(count[i]>=n)
		print acum[i];
}
