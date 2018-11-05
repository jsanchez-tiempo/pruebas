{
 count[$8]++;

 if(acum[$8]=="")
	acum[$8]=$0;
 else
	acum[$8]=acum[$8]"\n"$0;
}
END{
 for(i=1;count[i]>0;i++)
	if(count[i]>=n)
		print acum[i];
}
