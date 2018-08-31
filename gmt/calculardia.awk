function average_interp_cubic(row)
{
  a_1 = row[1] + row[1];
  a0  = row[2] - row[0];
  a1  = 2.0 * row[0] - 5.0 * row[1] + 4.0 * row[2] - row[3];
  a2  = row[3] - row[0] + 3.0 * ( row[1] - row[2] );
  return 0.5 * ( a_1 + a0 / 2.0 + a1 / 3.0 + a2 / 4.0 );
}

function average_array_cubic(d, nd)
{

  ave = 0.0;
  if ( nd < 4 )
    {
      for ( i = 0; i < nd; i++ )
        {
          ave += d[i];
        }
      return ( ave / nd );
    }

  for ( i = 0; i < nd - 1; i++ )
    {
      if ( i == 0 )
        {
          dx[0] = 2 * d[0] - d[1];
          dx[1] = d[0];
          dx[2] = d[1];
          dx[3] = d[2];
        }
      else if ( i == nd - 2 )
        {
          dx[0] = d[nd - 3];
          dx[1] = d[nd - 2];
          dx[2] = d[nd - 1];
          dx[3] = 2 * d[nd - 1] - d[nd - 2];
        }
      else
        {
          dx[0] = d[i - 1];
          dx[1] = d[i];
          dx[2] = d[i + 1];
          dx[3] = d[i + 2];
        }
      ave += average_interp_cubic(dx);
    }
  return ( ave / ( nd - 1 ) );
}


function max(a,b)
{
	return 	(a < b) ? b : a;
}
function min(a,b)
{
	return 	(a > b) ? b : a;
}

function calcularIcono(nicono, apcp, tcdc){
  nub2 = 55.0;
  nub3 = 96.0;

  if ( tcdc > nub3 )
    {
      switch ( nicono )
        {
        case 2:
        case 3:
          nicono = 4;
          break;
        case 5:
        case 6:
          nicono = 7;
          break;
        case 8:
        case 9:
          nicono = 10;
          break;
        case 11:
        case 12:
          nicono = 13;
          break;
        case 14:
        case 15:
          nicono = 16;
          break;
        case 17:
        case 18:
          nicono = 19;
          break;
        default:
          nicono = nicono;
          break;
        }
    }
  else if ( tcdc > nub2 )
    {
      switch ( nicono )
        {
        case 2:
        case 4:
          nicono = 3;
          break;
        case 5:
        case 7:
          nicono = 6;
          break;
        case 8:
        case 10:
          nicono = 9;
          break;
        case 11:
        case 13:
          nicono = 12;
          break;
        case 14:
        case 16:
          nicono = 15;
          break;
        case 17:
        case 19:
          nicono = 18;
          break;
        default:
          nicono = nicono;
          break;
        }
    }
  else
    {
      switch ( nicono )
        {
        case 3:
        case 4:
        case 6:
        case 7:
        case 9:
        case 10:
        case 12:
        case 13:
        case 15:
        case 16:
        case 18:
        case 19:
          nicono = nicono - 1;
          break;
        case 1:
        case 2:
          if (tcdc < 10.0)
            nicono = 1;
          break;
        default:
          nicono = nicono;
          break;
        }
    }

  if ( apcp >= 10.0 )
    {
      switch ( nicono )
        {
        case 5:
          nicono = 8;
          break;
        case 6:
          nicono = 9;
          break;
        case 7:
          nicono = 10;
        default:
          break;
        }
    }


  return nicono;
	
}
NR==1{
    id=$1;
    nombre=$3
    latitud=$4
    longitud=$5
    fechalocal=$6
    fechautc=$7
    t2m=$8
    t2mmax=$9
    t2mmin=$10
    arrayTcdc[0]=$11
#    tcdc=$11
    apcp=$12
    nicono=int($13/32)
    nhoras=1
}
NR>1{
	if(id==$1){
		t2mmax=max(t2mmax,$9);
		t2mmin=min(t2mmin,$9);
		apcp+=$12; ######
		nicono=max(nicono,int($13/32));
#		tcdc+=$11;
		arrayTcdc[nhoras]=$11
		nhoras++;	
	}
	else{
#		tcdc/=nhoras;
		tcdc=average_array_cubic(arrayTcdc, nhoras);
		printf "%d;%s;%s;%s;%s;%s;%.2f;%.2f;%.2f;%.2f;%d\n",id,nombre,latitud,longitud,fechalocal,fechautc,t2mmax-273.15,t2mmin-273.15,tcdc,apcp,calcularIcono(nicono,apcp,tcdc);
		
		
		id=$1;
 		nombre=$3
 		latitud=$4
 		longitud=$5
 		fechalocal=$6
 		fechautc=$7
 		t2m=$8
 		t2mmax=$9
 		t2mmin=$10
# 		tcdc=$11
 		arrayTcdc[0]=$11
 		apcp=$12
 		nicono=int($13/32)
 		nhoras=1
		
	}

}
END{
	tcdc/=nhoras;
	printf "%d;%s;%s;%s;%s;%s;%.2f;%.2f;%.2f;%.2f;%d\n",id,nombre,latitud,longitud,fechalocal,fechautc,t2mmax-273.15,t2mmin-273.15,tcdc,apcp,calcularIcono(nicono,apcp,tcdc);
}
