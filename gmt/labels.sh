#!/bin/bash
###############################################################################
# Script que lee un fichero con las fechas y coordenadas cuando y donde va a aparecer
# una etiqueta en el vídeo, y genera otro fichero con la configuración de la etiqueta
# que podrá ser leido por el script animacion.sh.
#
#
# labels.sh [filecoords] [-n nombre] [-c color] [-b bgcolor] [-f fontsize] [-g geogcfgfile] [-m minutos] [-h]
#           [--xsize=xsize] [--ysize=ysize]  [--xdes=xdes] [--ydes=ydes]
#
#
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      29/10/2018
###############################################################################


# Nombre del script.
scriptName=`basename $0`

# Función que define la ayuda sobre este script.
function usage() {

      echo
      echo "Genera un fichero de configuración para una etiqueta que puede ser leido por animación.sh."
      echo "El resultado se muestra por salida estandar."
      echo
      echo "Uso:"
      echo "${scriptName} [filecoords] [-n nombre] [-c color] [-b bgcolor] [-f fontsize] [-g geogcfgfile] [-m minutos] [-h]"
      echo "                  [--xsize=xsize] [--ysize=ysize]  [--xdes=xdes] [--ydes=ydes]"
      echo
      echo " filecoords :     Fichero de coordenadas donde cada fila tiene que tener el formato \"fecha x y [smooth]\". "
      echo "                  'fecha' debe tener el formato 'yyyyMMddhhmm', 'x' e 'y' pueden ser coordenadas cartesianas o "
      echo "                  geográficas y 'smooth' (opcional) es un valor de transparencia entre 0 (transparente) y 1 (opaco)."
      echo "                  Si no se especifica ningún fichero se leera desde la entrada estandar."
      echo " -n nombre:       Texto que va a llevar la etiqueta. Por defecto 'titulo'."
      echo " -c color:        Color del texto de la etiqueta. Por defecto 'black'."
      echo " -b bgcolor:      Color de la caja que contiene al texto en la etiqueta. Por defecto 'transparent'."
      echo " -f fontsize:     Tamaño de fuente del texto en la etiqueta. Por defecto 30."
      echo " -g geogcfgfile:  Fichero de configuración geográfica. Trasforma las coordenadas cartesianas de 'filecoords' a "
      echo "                  coordenadas geográficas en base al este fichero. Por defecto no se hace esta transformación. "
      echo " -m minutos:      Minutos de resampleo. Hace un resampleo cada 'minutos' minutos si la distancia horaria de "
      echo "                  las fechas entre filas es mayor, utilizando interpolación cúbica. Por defecto nos se hace. "
      echo " --xsize=xsise:   Ancho de la caja que contiene el texto de la etiqueta. Por defecto 150."
      echo " --ysize=ysise:   Alto de la caja que contiene el texto de la etiqueta. Por defecto 50."
      echo " --xdes=xdes:     Desplazamiento X en pixeles de la etiqueta. Por defecto 0."
      echo " --ydes=ydes:     Desplazamiento Y en pixeles de la etiqueta. Por defecto 0."
      echo " -h:              Muestra esta ayuda."
      echo
      echo "El fichero default.cfg define las variables de configuración de este comando."

}



# Parsea los argumentos pasados al comando a través de la línea de comandos
function parseOptions() {
    OVERWRITE=0

    fileinput="/dev/stdin"

    # Expresiones regulares
    refloat="^[+-]?[0-9]+([.][0-9]+)?$"
    reint="^[+-]?[0-9]+$"
    repos="^[0-9]+$"
    refecha="^[0-9]{10}$"
    rebin="^[0-1]{1}$"
    reopt="^-.*$"

    # Si no hay argumentos configuración por defecto
    if [ $# -eq 0 ]
    then
        return 0
    fi

    # Si el primer argumento no es una opción, debe ser un fichero
    if ! [[ $1 =~ ${reopt} ]]
    then
        fileinput=$1;
        [ ! -f ${fileinput} ] && \
            { echo "Error: no existe el fichero ${fileinput}" >&2; usage; exit 1; }

    fi


    # Chequeamos el resto de opciones
    options=$(getopt -o hn:c:b:f:g:m: --long xsize: --long ysize: --long xdes: --long ydes: -- "$@")

    if [ $? -ne 0 ]
    then
        usage; exit 1
    fi


    # set -- opciones: cambia los parametros de entrada del script por los especificados en opciones y en ese orden. la opción "--"
    # hace que tenga en cuenta tambien los argumentos que empiezan por "-" (sino los omite).
    eval set -- "${options}"

    while true; do
        case "$1" in
        -n)
            shift
            name=$1;
            ;;
        -c)
            shift
            color=$1;
            ;;
        -b)
            shift
            bgcolor=$1
            ;;
        --xsize)
            shift
            xsize=$1
            ! [[ ${xsize} =~ ${repos} ]] || [ ${xsize} -le 0 ] &&  \
                { echo "Error: --xsize debe ser positivo mayor que 0" >&2; usage; exit 1; }
            ;;
        --ysize)
            shift
            ysize=$1
            ! [[ ${ysize} =~ ${repos} ]] || [ ${ysize} -le 0 ] &&  \
                { echo "Error: --ysize debe ser positivo mayor que 0" >&2; usage; exit 1; }
            ;;

        --xdes)
            shift
            xdes=$1
            ! [[ ${xdes} =~ ${repos} ]] || [ ${xdes} -le 0 ] &&  \
                { echo "Error: --xdes debe ser positivo mayor que 0" >&2; usage; exit 1; }
            ;;
        --ydes)
            shift
            ydes=$1
            ! [[ ${ydes} =~ ${repos} ]] || [ ${ydes} -le 0 ] &&  \
                { echo "Error: --ydes debe ser positivo mayor que 0" >&2; usage; exit 1; }
            ;;
        -f)
            shift
            fontsize=$1
            ! [[ ${fontsize} =~ ${repos} ]] || [ ${fontsize} -le 0 ] &&  \
                { echo "Error: --fontsize debe ser positivo mayor que 0" >&2; usage; exit 1; }
            ;;

        -g)
            shift
            geogfile="${GEOGCFGDIR}/$1"
            ;;
        -m)
            shift
            mins=$1
            ! [[ ${mins} =~ ${repos} ]] || [ $(( 60 % ${mins} )) -ne 0 ] && \
                { echo "Error: El valor mins debe entero positivo y divisor de 60." >&2; usage; exit 1; }
            ;;

        -h)
            usage
            exit 0
            ;;

        --)
            shift
            break
            ;;

        esac
        shift
    done
}



cd `dirname $0`

# Cargamos las variables por defecto, las funciones y la configuración de las variables de los grids
source defaults.cfg
source funciones.sh
source funciones-variables.sh
source variables.sh


#### Parámetros por defecto

# Texto de la etiqueta
name="titulo"
# Color de fondo de la caja de la etiqueta
bgcolor="transparent"
# Color del texto de la etiqueta
color="black"
# Ancho de la caja de la etiqueta
xsize=150
# Alto de la caja de la etiqueta
ysize=50
# Desplazamiento x en pixeles con respecto a la posición de la etiqueta
xdes=0
# Desplazamiento y en pixeles con respecto a la posición de la etiqueta
ydes=0
# Tamaño de fuente del texto
fontsize=30
# Factor de suavizado para cuando aparecen o desaparecen las etiquetas
smooth=4

parseOptions "$@"


# Comprobamos que existe el ficheros de configuración geográfica
[ ! -z ${geogfile} ]  && [ ! -f "${geogfile}" ] && \
    { echo "Error: No existe el fichero de configuración geográfica ${geogfile}" >&2; usage; exit 1; }

# Si hemos pasado un fichero configuración geográfica, entendemos que las coordenadas de la entrada
# son cartesianas y las deberemos pasar a geográficas en función de la J y la R.
comando="cat"
if [ ! -z ${geogfile} ]
then
    source ${geogfile}

    comando=""
    # Si la proyección es global, debemos hacer una primera tranformación desde las coordenadas
    # cartesianas de la imagen a las coordenadas cartesianas de la proyección
    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`
        comando="${GMT} mapproject -JX${xlength}c/${ylength}c ${RAMP} -I -i1,2,0,3 -o2,0,1,3  | "
    fi

    comando="${comando}${GMT} mapproject ${R} ${J} -I -i1,2,0,3 -o2,0,1,3"
fi

# Si hemos especificado un valor de resampleado en el tiempo lo aplicamos
timecommand="cat"
if [ ! -z ${mins} ]
then
    timecommand="awk '{print substr(\$1,0,8)\"T\"substr(\$1,9,4),\$2,\$3,\$4}' | ${GMT} sample1d -T0 -f0T -I${mins}  -Fc \
--FORMAT_DATE_IN='yyyymmdd' --FORMAT_CLOCK_IN='hhmm' \
--FORMAT_DATE_OUT='yyyymmdd' --FORMAT_CLOCK_OUT='hhmm' \
 --TIME_UNIT=m | sed 's/T//'"
fi



cat ${fileinput} | eval ${comando} | eval ${timecommand} | awk -v name="${name}" -v color=${color} -v bgcolor=${bgcolor} -v fontsize=${fontsize}\
 -v xdes=${xdes} -v ydes=${ydes} -v xsize=${xsize} -v ysize=${ysize} -v nf=${smooth}\
 'BEGIN{
        OFS=";"
        nfields=4;
     }\
     NR==1{
        "date -u -d \""substr($1,0,8)" "substr($1,9,4)"\" +%s" | getline fecha;
     }

     # Chequeamos que todas las filas cumplen el formato y los requisitos
     NR>1{
        fechaanterior=fecha;
        "date -u -d \""substr($1,0,8)" "substr($1,9,4)"\" +%s" | getline fecha;

        # Si hay diferencias de tiempo entre dos filas distintas salimos
        if (NR>2 && fecha-fechaanterior != diff){
            print "Error: La distancia en tiempo entre dos filas debe ser siempre la misma" > "/dev/stderr";
            _assert_exit=1;
            exit 1;
        }
        diff=fecha-fechaanterior;

        # Si la fecha es menor que una fecha de una fila anterior salimos
        if(fechaanterior>=fecha){
            print "Error" > "/dev/stderr";
            _assert_exit=1;
            exit 1;
        }

     }
     {\
        if(NF<4)
            nfields=3;
        row[NR-1]["fecha"]=$1;\
        row[NR-1]["x"]=$2;\
        row[NR-1]["y"]=$3;\
        row[NR-1]["smooth"]=$4;\
     }\
  END{\
        if(_assert_exit==1)
            exit 1;

        for (i=0; i<NR; i++){
            # Si no está la columna de transparencia la calculamos nosotros
            if(nfields==3){
                fadein=1;
                if(i<nf)
                    fadein=(i+1)/nf;
                fadeout=1;
                if(i>=NR-nf)
                    fadeout=(NR-i)/nf;
                fade=(fadein<fadeout)?fadein:fadeout;
            }else
                fade=row[i]["smooth"];

            printf "%s;%s;%s;%s;%s;%s;%s;%.4f;%s;%s;%s;%s\n",row[i]["fecha"],row[i]["x"],row[i]["y"],name,fontsize,color,bgcolor,fade,xdes,ydes,xsize,ysize;
        }

     }'
