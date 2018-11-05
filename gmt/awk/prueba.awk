BEGIN{
    inicial=inicio - int(inicio/10800)*10800;

}
{
    columna=int((inicial+$5)/10800)+1+5;
    columna2=int((inicial+$5)/10800)+2+5;


    peso1=((inicial+$5)%10800)/10800;
    peso2=1-peso1;

    /*print columna,columna2,peso1,peso2;*/

    print $1,$2,$3,$4,$5,$columna*peso2+$columna2*peso1,columna, columna2, peso1, peso2
}
