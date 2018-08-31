BEGIN{
    direcciones="N_NE_E_SE_S_SO_O_NO";
    split(direcciones, arrayDirecciones, "_");
}
{
    dd=$3;
    ff=$2;

    ix=int(ff+0.5);
    ib=int((dd + 22.5) % 360.0 / 45.0 + 1.0);
    id=ib;

    if ( ix >= 0 && ix <= 1 )
      id=ib;
    else if ( ix < 6 )
      id=ib + 8;
    else if ( ix < 12)
      id=ib + 2 * 8;
    else if ( ix < 20)
      id=ib + 3 * 8;
    else if ( ix < 29)
      id=ib + 4 * 8;
    else if ( ix < 39)
      id=ib + 5 * 8;
    else if ( ix < 50)
      id=ib + 6 * 8;
    else if ( ix < 62)
      id=ib + 7 * 8;
    else if ( ix < 75)
      id=ib + 8 * 8;
    else if ( ix < 89)
      id=ib + 9 * 8;
    else if ( ix < 103)
      id=ib + 10 * 8;
    else if ( ix < 118)
      id=ib + 11 * 8;
    else
      id=ib + 12 * 8;



  print $1" "id" "arrayDirecciones[ib];
}
