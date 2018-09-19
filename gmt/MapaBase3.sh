#!/bin/bash
###############################################################################
# Script que genera los mapas y el fichero de información geográfica
# que los scripts de animación tomarán como base.
# Se generan 4 archivos en formato PNG y uno con extensión CFG: 1 imagen con el
# mapa completo, 1 imagen sin el fondo del mar, 1 imagen con las fronteras de
# los continentes en negro, 1 imagen con las fronteras en blanco y el fichero
# de configuración.
#
#
# Uso:
# MapaBase3.sh lon lat [-f file] [-z zoom] [-x xsize] [-y ysize] [--xdes xdes]
#              [--ydes ydes] [-g globefile] [-r res] [-c cod] [-s seaimage] [-o]
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      12/09/2018
###############################################################################

# Nombre del script.
scriptName=`basename $0`


# Función que define la ayuda sobre este script.
function usage() {
      echo
      echo "Genera los mapas base y el fichero de configuración geográfica"
      echo
      echo "Uso:"
      echo "${scriptName} lon lat [-f file] [-z zoom] [-x xsize] [-y ysize] [--xdes xdes] [--ydes ydes] "
      echo "                      [-g globefile] [-r res] [-c cod] [-s seaimage] [-o]"
      echo
      echo "   lon :         Longitud del punto central de la proyección en grados [-|+]GG.G"
      echo "                 GG.G = grados entre -360.0 y 360.0"
      echo "   lat :         Latitud del punto central de la proyección en grados [-|+]GG.G"
      echo "                 GG.G = grados entre 0.0 y 90.0"
      echo "   -f file:      Nombre base de los ficheros de salida. No se debe poner la extensión. Por defecto \"mapa\"."
      echo "   -z zoom:      Un pixel en el centro equivale a 30/zoom segundos. Por defecto 1."
      echo "   -x xsize:     Tamaño horizontal en pixels. Por defecto 1920."
      echo "   -y ysize:     Tamaño vertical en pixels. Por defecto 1080."
      echo "   --xdes xdes:  Desplazamiento horizontal en pixeles (solo mapas globales). Por defecto 0."
      echo "   --ydes ydes:  Desplazamiento vertical en pixeles (solo mapas globales). Por defecto 0."
      echo "   -g globefile: Fichero de altitud a partir del cual se generan los mapas de salida. Por defecto coge el"
      echo "                 fichero con nombre \"globe[.*].grd\" dentro del directorio \${GLOBEDIR} con menor resolución"
      echo "                 posible que se ajuste al zoom seleccionado. "
      echo "   -r res:       Resolución de los mapas. Coge el fichero de altitud con nombre \"globe\${res}.grd\". Si no"
      echo "                 lo encuentra se crea a partir del fichero de altitud definido en \${GLOBEFILESOURCE} o"
      echo "                 del pasado a través de la opción -g."
      echo "   -c cod:       Código de región. Pintará los continentes en gris excepto el país o la región indicada"
      echo "                 que se pintará con colores. Por defecto no se define ningún código."
      echo "   -s seaimage:  Fichero de imagen del mar. Si el fichero tiene formato de imagen lo utilizará para generar"
      echo "                 el mapa y lo añadirá al fichero de configuración. Si el fichero tiene formato de vídeo lo "
      echo "                 añade al fichero de configuración pero no lo utiliza para generar el mapa. Por defecto se "
      echo "                 utiliza el definido en la variable \${fondomar}."
      echo "   -o:           Sobreescribe todos los ficheros sin preguntar si existen."
      echo "   -h:           Muestra esta ayuda."
      echo
      echo "El fichero default.cfg define las variables de configuración de este comando."


}

# Parsea los argumentos pasados al comando a través de la línea de comandos
function parseOptions() {
    OVERWRITE=0

    if [ $# -eq 0 ]
    then
       echo "error: el número de argumentos mínimo es 2" >&2; usage; exit 1
    fi

    if [ $1 != "-h" ]
    then
        if [ $# -lt 2 ]
        then
           echo "error: el número de argumentos mínimo es 2" >&2; usage; exit 1
        fi

        # Expresiones regulares
        refloat="^[+-]?[0-9]+([.][0-9]+)?$"
        reint="^[+-]?[0-9]+$"
        repos="^[0-9]+$"
        reres="^[0-9]+[m|s]+$"

        # Chequeamos la longitud
        lon=$1
        if ! [[ ${lon} =~ $refloat ]] ; then
           echo "error: $lon no es un número" >&2; usage; exit 1
        fi

        if (( $(echo "${lon} < -360 || ${lon} > 360 " | bc -l) ))
        then
           echo "error: longitud debe ser >= -360 y <= 360 " >&2; usage; exit 1
        fi
        shift;

        # Chequeamos la latitud
        lat=$1
        if ! [[ ${lat} =~ $refloat ]] ; then
           echo "error: $lat no es un número" >&2; usage; exit 1
        fi

        if (( $(echo "${lat} < -90 || ${lat} > 90 " | bc -l) ))
        then
           echo "error: latitud debe ser >= -90 y <= 90 " >&2; usage; exit 1
        fi

        shift;
    fi

    # Chequeamos el resto de opciones
    options=$(getopt -o hf:z:x:y:g:c:s:or: --long xdes: --long ydes: -- "$@")


    # set -- opciones: cambia los parametros de entrada del script por los especificados en opciones y en ese orden. la opción "--"
    # hace que tenga en cuenta tambien los argumentos que empiezan por "-" (sino los omite).
    eval set -- "${options}"

    while true; do
        case "$1" in
        -f)
            shift
            outputFile=$1
            ;;
        -z)
            shift
            zoom=$1
            if ! [[ ${zoom} =~ $refloat ]] ; then
               echo "error: zoom no es un número" >&2; usage; exit 1
            fi
            if (( $(echo "${zoom} <= -0" | bc -l) )); then
               echo "error: zoom debe ser mayor que 0" >&2; usage; exit 1
            fi
            if (( $(echo "${zoom} > 1000" | bc -l) )); then
               echo "error: zoom no puede ser mayor que 1000" >&2; usage; exit 1
            fi
            ;;
        -x)
            shift
            xsize=$1
            if ! [[ ${xsize} =~ $repos ]] ; then
                echo "error: xsize no es un número entero positivo" >&2; usage; exit 1
            fi
            ;;
        -y)
            shift
            ysize=$1
            if ! [[ ${ysize} =~ $repos ]] ; then
                echo "error: ysize no es un número entero positivo" >&2; usage; exit 1
            fi
            ;;
        -g)
            shift
            GLOBEFILE=$1
            ;;
        -r)
            shift
            resformat=$1
            if ! [[ ${resformat} =~ ${reres} ]] ; then
                echo "error: La resolución no tiene un formato correcto" >&2; usage; exit 1
            fi
            resolucion=`echo ${resformat} | sed 's/m/*60/;s/s//' | bc`
            ;;
        -s)
            shift
            if $(file -ib $1 | grep -q video)
            then
                fondomarvideo=$1
            elif $(file -ib $1 | grep -q image)
            then
                fondomar=$1
            else
                echo "error: El fichero de fondo de mar no existe o tiene un formato incorrecto" >&2; usage; exit 1
            fi
#
            ;;
        -c)
            shift
            cod=$1
            ;;
        -o)
            OVERWRITE=1
            ;;
        -h)
            usage
            exit 0
            ;;
        --xdes)
            shift;
            xdesinicial=$1
            if ! [[ ${xdesinicial} =~ $reint ]] ; then
                echo "error: xdes no es un número entero" >&2; usage; exit 1
            fi
            ;;
        --ydes)
            shift;
            ydesinicial=$1
            if ! [[ ${ydesinicial} =~ $reint ]] ; then
                echo "error: ydes no es un número entero" >&2; usage; exit 1
            fi
            ;;
        --)
            shift
            break
            ;;
        esac
        shift
    done





}


# Chequea un directorio
function checkdir () {
    local dir=$@
    if [ ! -d ${dir} ] && [ ${OVERWRITE} -eq 0 ]
    then
        echo "No existe el directorio ${dir}. ¿Deseas crearlo [(s)/n]?"
        read var <&0
        if [ ! -z ${var} ] && [ ${var,,} != "s" ];then
            exit 0;
        fi
    fi
    mkdir -p ${dir} || exit 1
}

# Chequea los directorios y los crea si no existe
function checkDIRS () {

    checkdir ${PREFIX}
    checkdir ${DIRROTULOS}
    checkdir ${DIRESTILOS}
    checkdir ${DIRLOGOS}
    checkdir ${DIRFONDOS}
    checkdir ${DIRFRONTERAS}
    checkdir ${CFGDIR}
    checkdir ${CPTDIR}
    checkdir ${GLOBEDIR}

}

# Escribe el fichero de configuración geográfico
function writeGeogCFG () {
    echo "### Proyección"
    echo "R=${R}"
    echo "J=${J}"
    echo
    echo "### Resolución"
    echo "resolucion=${resformat}"
    echo "GLOBEFILE=${GLOBEFILE}"
    echo
    echo "### Dimensiones"
    echo "xsize=${xsize}"
    echo "ysize=${ysize}"
    echo "dpi=${dpi}"
    echo
    if [ ! -z ${global} ] && [ ${global} -eq 1 ]
    then
        echo "### Global"
        echo "global=1"
        echo "RAMP=${RAMP}"
        # Le aplicamos el efecto de sombra de la tierra para quede más tridimensional
        if [ ! -z ${sombratierra} ] && [  ${sombratierra} -eq 1 ]
        then
            echo "filesombra=${outputFinalSombraPNG}"
        fi


        echo
    fi

    echo "### Fondo Mar"
    if [ ! -z ${fondomarvideo} ]
    then
        echo "fondomar=${fondomarvideo}"
    else
        echo "fondomar=${fondomarsrc}"
    fi

    echo
    echo "### Fondos"
    echo "fondoPNG=${outputFinalPNG}"
    echo "fondoPNG=${outputFinalsmPNG}"
    echo "fronterasPNGw=${outputFinalbwPNG}"
    echo "fronterasPNGb=${outputFinalbbPNG}"
    echo "fronterasPNG=${outputFinalbbPNG}"
    echo

    if [ ! -z ${cod} ]
    then
        echo "### Código de región"
        echo "cod=${cod}"
    fi
}



# Función que cambia los valores de Tono/Saturación/Luminosidad en la escala HSL de un fichero de imagén. Lo hace como GIMP
# Parámetros:
#   $1: Fichero de imagen
#   $2: Valor que se suma al tono de la imagen. Entre -180 y 180
#   $3: Valor que se suma a la saturación de la imagen. Entre -100 y 100
#   $4: Valor que se suma a la luminosidad de la imagen. Entre -100 y 100
# Los cambios se realizan sobre el propio fichero de entrada
function changeHSL () {

    local file=$1
    local H=`awk -v h=$2 'BEGIN{printf "%.1f\n",100+h/180*100}'`
    local S=$((100+$3))
    local L=`awk -v l=$4 'BEGIN{printf "%.1f\n",100+l/2}'`


    if [ `echo "${L}<=100" | bc -l` -eq 1 ]
    then
        ${CONVERT} ${file} -modulate ${L},${S},${H} png32:${file}
    else
        # Si la luminosidad es mayor que 100 normalizamos el valor a añadir "l" entre 0 y 1. Establecemos la nueva
        # luminosidad como l*(100-L). Queda raro pero GIMP lo hace así
        L=`awk -v l=${L} 'BEGIN{printf "%.2f\n",l/100-1}'`
        dims=`${CONVERT} ${file} -format "%wx%h" info:`
        ${CONVERT} ${file} -modulate 100,${S},${H}  \( +clone \( +clone -colorspace HSL -separate \) \
          \( -clone -1 -size ${dims}  xc:white -compose minus -composite -evaluate multiply ${L} \) \
          \( -clone -1,-2 -compose plus -composite \) -delete 0,-2,-3 -combine -set colorspace HSL -colorspace sRGB \) \
          \( -clone 0 -channel A -separate \) -delete 0 -compose copy-opacity -composite png32:${file}
    fi


}


# Función que cambia el balance de color de los canales RGB de un fichero de imagén manteniendo la luminosidad
# Parámetros:
#   $1: Fichero de imagen
#   $2: Valor que se suma al canal R de la imagen. Entre 0 y 100
#   $3: Valor que se suma al canal G de la imagen. Entre 0 y 100
#   $4: Valor que se suma al canal B de la imagen. Entre 0 y 100
# Los cambios se realizan sobre el propio fichero de entrada
function colorBalance () {

    file=$1
    local R=`awk -v r=$2 'BEGIN{printf "%.2f\n",(100+r)/100}'`
    local G=`awk -v r=$2 'BEGIN{printf "%.2f\n",(100+g)/100}'`
    local B=`awk -v r=$2 'BEGIN{printf "%.2f\n",(100+b)/100}'`

    # Para mantener la luminosidad guardamos el canal L de la imagen original. En otra copia hacemos la transformación
    # sobre los canales R, G y B y pasamos la imagen a HSL eliminando el canal L. Por último juntamos el canal H y S de
    # la imagen transformada y el L de la imagen original. Si tiene canal alfa en la original también se guarda.
    ${CONVERT} ${file} \
     \( +clone \
        \( +clone -channel green -evaluate multiply ${G} +channel -channel blue -evaluate multiply ${B} +channel \
         -channel red -evaluate multiply ${R} +channel -colorspace HSL -separate -delete -1 \) \
        \( -clone 0 -colorspace HSL -separate -delete -2,-3  \) -delete 0 -combine -set colorspace HSL -colorspace sRGB  \) \
     \( -clone 0 -channel A -separate \) -delete 0 -compose copy-opacity -composite png32:${file}


}

# Función que dado un codigo de país, comunidad autónoma o provincia vuelca las coordenadas de sus poligonos en un fichero
# Parámetros:
#   $1: Fichero donde se guardan las coordenadas de la región
#   $2: Código de región
function buscarFrontera () {
    local file=$1
    local cod=$2

    array=(`echo ${cod} | tr '.' ' '`)
    if [ ${#array[@]} -eq 1 ]
    then
        ogr2ogr -where "ISO2='${cod}'" -f "GMT" ${file} ${DIRFRONTERAS}/gadm28_adm0.shp
    else
        i=$((${#array[@]}-1))
        ogr2ogr -where "HASC_${i}='${cod}'" -f "GMT" ${file} ${DIRFRONTERAS}/gadm28_adm${i}.shp
    fi

}

cd `dirname $0`

# Cargamos las variables de configuración y las funciones
source defaults.cfg
source funciones.sh

# Comprobación de que existe el software.
command -v ${GMT} > /dev/null 2>&1 || { echo "error: ${GMT} no está instalado." >&2 && exit 1; }
command -v ${CONVERT}  > /dev/null 2>&1 || { echo "error: ${CONVERT} no está instalado." >&2 && exit 1; }
command -v ${COMPOSITE}  > /dev/null 2>&1 || { echo "error: ${COMPOSITE} no está instalado." >&2 && exit 1; }




# Parseamos los argumentos de entrada
parseOptions $@

checkDIRS

printMessage "Generando mapas y archivo de configuración:"
printMessage "longitud: ${lon}, latitud: ${lat}, zoom: ${zoom}, ancho: ${xsize}, alto: ${ysize}"
printMessage "desplazamiento horizontal: ${xdesinicial}, desplazamiento vertical: ${ydesinicial}"


### COMPROBACIONES

# Comprobamos que el desplazamiento no es mayor que el tamaño
if [ ${xdesinicial} -lt -${xsize} ] ||  [ ${xdesinicial} -gt ${xsize} ]
then
    echo "error: el desplazamiento ${xdesinicial} no puede ser mayor que su tamaño ${xsize}" >&2
    exit 1
fi

if [ ${ydesinicial} -lt -${ysize} ] ||  [ ${xdesinicial} -gt ${ysize} ]
then
    echo "error: el desplazamiento ${ydesinicial} no puede ser mayor que su tamaño ${ysize}" >&2
    exit 1
fi


# Comprobamos que hay archivos de fronteras
array=(`echo ${cod} | tr '.' ' '`)
i=$((${#array[@]}-1))
if [ ! -z ${cod} ] && [ ! -f ${DIRFRONTERAS}/gadm28_adm${i}.shp ] && [ ! -f ${DIRFRONTERAS}/gadm28_adm${i}.dbf ] \
    && [ ! -f ${DIRFRONTERAS}/gadm28_adm${i}.dpg ] && [ ! -f ${DIRFRONTERAS}/gadm28_adm${i}.shx ] \
    && [ ! -f ${DIRFRONTERAS}/gadm28_adm${i}.prj ]
then
    echo "error: No se han encontrado los archivos de límites geográficos gadm28_adm${i}.* ." >&2
    exit 1
fi


# Comprobamos que existe el fondo del mar
if [ ${sombratierra} -eq 1 ] && [ ! -f ${filesombra} ]
then
    echo "error: No se ha encontrado el archivo de sombra ${filesombra}." >&2
    exit 1
fi

# Comprobamos que existe el fichero CPT
if [ ! -f ${CPTGLOBE} ]
then
    echo "error: No se ha encontrado el archivo CPT ${CPTGLOBE}." >&2
    exit 1
fi


# Comprobamos que existe el fondo del mar
if [ ! -f ${fondomar} ]
then
    echo "error: No se ha encontrado el archivo de fondo de mar  ${fondomar}." >&2
    exit 1
fi

# Copia el archivo de fondo del mar a la carpeta de fondos
if [ $(dirname $(realpath ${fondomar} )) !=  $(realpath ${DIRFONDOS}) ]
then
    if [ ${OVERWRITE} -eq 0 ]
    then
        echo "El archivo del fondo del mar no se encuentra en la carpeta de fondos. ¿Deseas copiarlo [(s)/n]?"
        read var <&0
        if [ ! -z ${var} ] && [ ${var,,} != "s" ];then
            exit 0;
        fi
    fi
    cp -f ${fondomar} ${DIRFONDOS}
    fondomar=${DIRFONDOS}/`basename ${fondomar}`
fi

fondomarsrc=${fondomar}


# Creamos el directorio temporal de trabajo
TMPDIR="/tmp/${scriptName}.$$"
#TMPDIR="/tmp/`basename $(type $0 | awk '{print $3}').$$`"
mkdir -p ${TMPDIR}

# Definimos que el script pare si se captura alguna señal de terminación o se produce algún error
trap "rm -rf ${TMPDIR}; echo 'error: señal interceptada. Saliendo' >&2;exit 1" 1 2 3 15
trap "echo 'error: ha fallado la ejecución. Saliendo' >&2;exit 1" ERR


# Definición de los ficheros de mapas de salida
#outputFinalPS=${DIRFONDOS}/${outputFile}.ps
outputFinalPNG=${DIRFONDOS}/${outputFile}.png # mapa completo
outputFinalsmPNG=${DIRFONDOS}/${outputFile}sm.png # sin mar
outputFinalbwPNG=${DIRFONDOS}/${outputFile}bw.png # fronteras blancas
outputFinalbbPNG=${DIRFONDOS}/${outputFile}bb.png # fronteras negras
outputFinalSombraPNG="${DIRFONDOS}/${outputFile}sombra.png" # Fichero de sombra (solo global)

# Si existe alguno preguntamos si se quiere sobreescribir
if ([ -f ${outputFinalPNG} ] || [ -f ${outputFinalsmPNG} ] || [ -f ${outputFinalbwPNG} ] || [ -f ${outputFinalbbPNG} ])&&[ ${OVERWRITE} -eq 0 ]
then
    echo "Ya existe un fichero con nombre ${outputPNG}. ¿Deseas sobreescribirlo [(s)/n]?"
    read var <&0
    if [ ! -z ${var} ] && [ ${var,,} != "s" ];then
        exit 0;
    fi
fi

# Solo sí el proceso entero ha finalizado correctamente se escribiran los mapas
outputPS=${TMPDIR}/${outputFile}.ps
outputPNG=${TMPDIR}/${outputFile}.png # mapa completo
outputsmPNG=${TMPDIR}/${outputFile}sm.png # sin mar
outputbwPNG=${TMPDIR}/${outputFile}bw.png # fronteras blancas
outputbbPNG=${TMPDIR}/${outputFile}bb.png # fronteras negras
outputSombraPNG="${TMPDIR}/${outputFile}sombra.png" # Fichero de sombra (solo global)


# Definición del ficheros de configuración
cfgFile=${CFGDIR}/${outputFile}.cfg

# Si existe preguntamos si se quiere sobreescribir
if [ -f ${cfgFile} ]&&[ ${OVERWRITE} -eq 0 ]
then
    echo "Ya existe un fichero con nombre ${cfgFile}. ¿Deseas sobreescribirlo [(s)/n]?"
    read var <&0
    if [ ! -z ${var} ] && [ ${var,,} != "s" ];then
        exit 0;
    fi
fi



# Definición de archivos temporales de trabajo
tmpFile="${TMPDIR}/kk"
tmpPS=${tmpFile}.ps
tmpPNG=${tmpFile}.png

fronterasFile="${TMPDIR}/kkf"
fronterasPNG=${fronterasFile}.png

gridFile="${TMPDIR}/grid"
gridPS=${gridFile}.ps
gridPNG=${gridFile}.png

tmpREG="${TMPDIR}/tmpREG.gmt"


# Calculamos la altura de la imagen Y en cm y el dpi (pixeles por pulgada)
ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`
dpi=`awk -v cm2inch=${cm2inch} -v xlength=${xlength} -v xsize=${xsize} 'BEGIN{printf "%d\n",int(xsize/(xlength*cm2inch)+0.5)}'`


# Calculamosel desplazamiento X y Y en cm
xdes=`awk -v xdes=${xdesinicial} -v xlength=${xlength} -v xsize=${xsize} 'BEGIN{printf "%.4f\n",xlength*xdes/xsize}'`
ydes=`awk -v ydes=${ydesinicial} -v ylength=${ylength} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",ylength*ydes/ysize}'`

# Establecemos la variable J de nuestra proyección (De momento solo orthográfica)
J="-JG${lon}/${lat}/${xlength}c"


####dlat=`${GMT} grdinfo ${GLOBEFILESOURCE} -C | awk '{print $9}'`


# Si se ha pasado un archivo globe como parámetro se define ese como fuente
if [ ! -z ${GLOBEFILE} ]
then
    GLOBEFILESOURCE=${GLOBEFILE}
fi

# Si se ha pasado una resolución como parámetro se establece esa como la resolución definitiva. Si no existe un fichero
# globe con esa resolución se crea a través del fichero globe fuente
if [ ! -z ${resolucion} ]
then
    printMessage "Resolución elegida: ${resformat}"
    GLOBEFILE="${GLOBEDIR}/globe${resformat}.grd"
    if [ ! -f ${GLOBEFILE} ]
    then
        printMessage "Generando fichero ${GLOBEFILE} a ${resformat} desde ${GLOBEFILESOURCE}"
        ${GMT} grdsample ${GLOBEFILESOURCE} -I${resformat} -G${GLOBEFILE}
    fi
else
    if [ ! -f ${GLOBEFILE} ]
    then
        echo "error: No existe el archivo de altitud ${GLOBEFILE}." >&2 && exit 1;
    fi
    resolucion=`awk -v grados=${dlat} -v z=${zoom} 'BEGIN{z=int(z); print int(3600*grados*z+0.5); }'`
    resformat=`awk -v secs=${resolucion} 'BEGIN{if(secs%60==0)print secs/60"m"; else print secs"s";}'`
    printMessage "Resolución calculada a partir del zoom: ${resformat}"
fi


# Calculamos el ancho que hay que ponerle a una proyección orthográfica global (J) para que el mapa se dibuje con la
# resolución deseada.
# Para ello calculamos la distancia d entre lat y lat+dlat en cm en el eje cartesiano suponiendo que en una proyección
# ortográfica global el centro de la proyección es el centro de la imagen y la imagen es cuadrada (en una imagen de tamaño
# 25cm el centro está en la coordenada 12.5 12.5). Esa distancia multiplicada por el zoom z representa a un pixel. Si tenemos
# ysize (1080) pixeles calculamos lo que mide el alto de la imagen en cms (h'). Calculamos la relación entre la altura
# definida para nuestra imagen h y la altura calculada h'. Esa relación h/h' la multiplicamos por el ancho definido
# w obteniendo el nuevo ancho que pondremos en la J.

newlat=`awk -v lat=${lat} -v dlat=${dlat} 'BEGIN{printf "%.4f\n",lat<0?lat+dlat:lat-dlat}'`
xlengthamp=`echo "${lon} ${newlat}" | ${GMT} mapproject ${J} -Rd |\
 awk -v zoom=${zoom} -v w=${xlength} -v h=${ylength} -v ysize=${ysize} \
 'function abs(v) {return v < 0 ? -v : v} {print abs(w*h/(zoom*ysize*(w*0.5 - $2)))}'`


#Si xlengthamp=11.9792 #Global actual
#Si xlengthamp=19.1482 #Semiglobal actual

JAMP="-JG${lon}/${lat}/${xlengthamp}c"


# Con la nueva J cogemos un rectángulo centrado en el centro de la proyección y de ancho y alto los w y h originales.
# Calculamos la longitud y latitud de la esquina inferior izquierda y de la esquina superior derecha que nos servirá
# para obtener la R
read lonmin latmin < <(awk -v w=${xlength} -v h=${ylength} -v wamp=${xlengthamp} 'BEGIN{x=y=wamp/2; printf "%.8f %.8f\n",x-w/2,y-h/2}' | ${GMT} mapproject -Rd ${JAMP} -I)
read lonmax latmax < <(awk -v w=${xlength} -v h=${ylength} -v wamp=${xlengthamp} 'BEGIN{x=y=wamp/2; printf "%.8f %.8f\n",x+w/2,y+h/2}' | ${GMT} mapproject -Rd ${JAMP} -I)


if [ -z ${GLOBEFILE} ]
then
    GLOBEFILE="${GLOBEDIR}/globe${resformat}.grd"
    if [ ! -f ${GLOBEFILE} ]
    then
        ficherosglobe=`ls -1 ${GLOBEDIR} |  sed -n '/globe.*.grd/p'`

        if [ $(ls -1 ${GLOBEDIR} |  sed -n '/globe.*.grd/p' | wc -l ) -eq 0 ]
        then
            if [ ! -f ${GLOBEFILESOURCE} ]
            then
             echo -n "error: no se encontró ningun fichero globe dentro de ${GLOBEDIR} ni tampoco el archivo " >&2
             echo "fuente ${GLOBEFILESOURCE}" >&2; exit 1
            elif [ ${OVERWRITE} -eq 0 ]
            then
                echo "No se encontró ningun fichero globe dentro de ${GLOBEDIR}. ¿Deseas crear globe${resformat}.grd [(s)/n]?"
                read var <&0
                if [ ! -z ${var} ] && [ ${var,,} != "s" ];then
                    exit 0;
                fi
            fi
            ${GMT} grdsample ${GLOBEFILESOURCE} -I${resformat} -G${GLOBEFILE}

        fi

        # Si el fichero no existe se busca la resolución mayor más proxima a la resolución deseada
        rescercana=`ls -1 ${GLOBEDIR} |  sed -n '/globe.*.grd/p' | sed 's/globe\(.*\).grd/\1/;s/s//;s/m/\*60/' | bc \
         | sort -n | awk -v res=${resolucion} 'NR==1{anterior=$1}{if($1>res){print anterior; noend=1; exit;}anterior=$1}END{if(noend==0)print $1}' \
         | awk '{secs=$1; if(secs%60==0)print secs/60"m"; else print secs"s";}'`
        GLOBEFILE="${GLOBEDIR}/globe${rescercana}.grd"
        printMessage "No existe el fichero globe${resformat}.grd. Estableciendo resolución a ${rescercana}."

    fi
fi

# Definimos la R
R="-R${lonmin}/${latmin}/${lonmax}/${latmax}+r"


# Si alguna de las coordenadas es NaN, el mapa es global
if [ ${lonmin} == "NaN" ] || [ ${latmin} == "NaN" ] || [ ${lonmax} == "NaN" ] || [ ${latmax} == "NaN" ]
then
    printMessage "El mapa es Global. Ajustando J y R a -Rd."
    global=1

    # R es global
    R="-Rd"
    J=${JAMP}

    # RAMP en coordenadas cartesianas nos servirá para transformar los grids de las variables meteorológicas para
    # poder generar los frames
    RAMP=`awk -v xlength=${xlength} -v xlengthamp=${xlengthamp} -v ylength=${ylength} -v xdes=${xdes} -v ydes=${ydes} \
    'BEGIN{x=(xlength-xlengthamp)/2; y=(xlengthamp-ylength)/2;   printf "-R%.4f/%.4f/%.4f/%.4f\n",\
    -x-xdes,xlength-x-xdes,y-ydes,xlengthamp-y-ydes}'`
else
    xdes=0
    ydes=0
fi


#Ejemplos
############## ydes=0
#grdcut kk.nc -R0/19/2.4688/16.5313 -Gkk2.nc   # (19-14.0625)/2=2.4688
#grdproject kk2.nc -JX25c/14.0625c -R-3/22/2.4688/16.5313 -Gkk3.nc # (25-19)/2=3
#${GMT} grdimage kk3.nc   -E192 -JX25c/14.0625c -R0/25/0/14.0625 -Xc -Yc --PS_MEDIA=25cx14.0625c -P -n+c   > prueba.ps

############## ydes=-275
#grdcut kk.nc -R-3/22/6.0495/20.112 -Gkk2.nc   # 275/1080×14,0625=3.5807; 3.5807+2.4688=6.0495; 16.5313+2.4688=20.112
#grdproject kk2.nc -JX25c/14.0625c -R-3/22/6.0495/20.112 -Gkk3.nc #
#${GMT} grdimage kk3.nc   -E192 -JX25c/14.0625c -R0/25/0/14.0625 -Xc -Yc --PS_MEDIA=25cx14.0625c -P -n+c   > prueba.ps



printMessage "Generando mapas"

# Dimensiones en cm para la proyección dada
w=${xlength}
h=${ylength}

X="-Xc${xdes}c"
Y="-Yc${ydes}c"

# Creamos el fichero base en donde pintamos el fondo gris de los continentes con las dimensiones anteriores
${GMT} psbasemap ${J} ${R} -B+n ${X} ${Y} --PS_MEDIA="${w}cx${h}c" -P -K > ${outputPS}
# Creamos el fichero en donde pintamos el país seleccionado con relieve con las dimensiones anteriores
${GMT} psbasemap ${J} ${R} -B+n ${X} ${Y} --PS_MEDIA="${w}cx${h}c" -P -K > ${tmpPS}


#Si se ha definido un país en cod pintamos los continentes en gris y solo pintamos en color la región
if [ ! -z ${cod} ]
then
    printMessage "Estableciendo región con código ${cod}"
    buscarFrontera ${tmpREG} ${cod} 2> /dev/null
    nlines=$(sed '/^#/d' ${tmpREG}| wc -l)
    if [ ${nlines} -gt 0 ]
    then
        ${GMT} pscoast ${J} ${R} -E=EU,=AF -A500 -Df -Ggray75 ${X} ${Y} --PS_MEDIA="${w}cx${h}c" -P -K -O >> ${outputPS}
        ${GMT} psclip ${tmpREG} ${J} ${R} -K -O ${X} ${Y} --PS_MEDIA="${w}cx${h}c" -P >> ${tmpPS}
    else
        echo "error: no se encontró el código ${cod}" >&2; usage; exit 1
    fi

fi

# Pintamos el fichero GLOBE
${GMT} grdimage  -Q -E${dpi} ${J} ${R} ${X} ${Y} ${GLOBEFILE} -C${CPTGLOBE} --PS_MEDIA="${w}cx${h}c" -P -K -O >> ${tmpPS}



# Si se definió un país
if [ ! -z ${cod} ]
then
    ${GMT} psclip ${J} ${R} -O -K -C >> ${tmpPS}
fi

# Convertimos el mapa de relieve a formato PNG
${GMT} psbasemap ${J} ${R} -B+n -O >> ${tmpPS}
${GMT} psconvert -E${dpi} ${tmpPS}  -P -TG -Qg1 -Qt4

# Le cambiamos el tono, le quitamos saturación y le damos luminosidad
changeHSL ${tmpPNG} 8 -40 30

# Cambiamos el balance de colores para que salga un tono más anaranjado
colorBalance ${tmpPNG} 7 -2 -5

# Le quitamos contraste a la imagen
${CONVERT} ${tmpPNG} -level -15%,105% png32:${tmpPNG}

# Le añadimos un borde blanco alrededor del mapa de relieve.
# Sobre una imagen umbralizada en blanco aplicamos una dilatación y sobreponemos la original sobre esta
${CONVERT} ${tmpPNG} \( +clone -background black -flatten -white-threshold 0% -morphology Dilate Octagon:2\
 -transparent black -blur 0x0.5 \) +swap -composite png32:${tmpPNG}



${GMT} psbasemap ${J} ${R} -B+n -O >> ${outputPS}
${GMT} psconvert -E${dpi} ${outputPS} -P -TG -Qg1 -Qt4

# Para sacar las fronteras sobre un mapa con región añadimos bordes blancos al mapa en gris, umbralizamos para quedarnos
# con los bordes blancos y los pintamos con un gris claro. Luego le superpondremos los bordes en blanco de la regións
# seleccionada
if [ ! -z ${cod} ]
then
    ${CONVERT} ${outputPNG} \( +clone -background black -flatten -white-threshold 10% -morphology Dilate Octagon:2\
     -transparent black -blur 0x0.5 \) +swap -composite \( +clone -background white -flatten -negate  \) +swap -composite -threshold 98%\
     -transparent black -fill lightgray -opaque white  png32:${fronterasPNG}
fi



# Unimos el mapa con relieve de la región seleccionada con el del mapa de los continentes en gris
${COMPOSITE} ${tmpPNG} ${outputPNG} png32:${outputPNG}



if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then

    # Creamos una una mascara en blanco para el globo sobre un fondo negro
    ${GMT} pscoast ${J} ${R} ${X} ${Y} -Swhite -Gwhite --PS_MEDIA="${w}cx${h}c" -P > ${tmpPS}
    ${GMT} psconvert ${tmpPS} -E${dpi} -P -TG -Qg1 -Qt4

    ${CONVERT} \( -size ${xsize}x${ysize} xc:black \) ${tmpPNG} -composite -white-threshold 0% ${tmpPNG}

    # Sobre la mascara creamos el efecto de luz que hay en el borde del planeta
    ${CONVERT} ${tmpPNG} -transparent black \( +clone  -blur 0x20 \) -compose Out -composite  png32:${TMPDIR}/difu.png

    # Al hacer el dilatado en los bordes del planeta se queda una línea blanca. Se lo quitamos con la mascara
    # Al aplicar el suavizado de las fronteras se crean transparencias y con flatten y el transparent se quedaba un
    # borde negro. Para solucionarlo se separa el canal alpha de la parte visible y se aplica la mascara a cada parte
    # por separado para después volver a unirlos
    ${CONVERT} ${tmpPNG} ${outputPNG} \( +clone -channel RGB -separate -combine -background black -flatten \) -swap 0,1 \
     \( -clone -1,-2 -compose multiply -composite  -transparent black \) \( -clone 0 -channel A -separate +channel \) \
     \( -clone 1,-1 -compose multiply -composite \) -delete 0,1,2,4 -compose copy-opacity -composite   png32:${outputPNG}

    # Aplicamos la mascara a la imagen del mar
    ${CONVERT} ${tmpPNG} ${fondomar} -compose multiply -composite -transparent black  png32:${tmpPNG}
    fondomar=${tmpPNG}
fi


# Le añadimos una sombra a los continentes
dims=`${CONVERT} ${outputPNG} -format "%wx%h" info:`
${CONVERT} ${outputPNG} \( +clone -background gray -shadow 30x3+3+3 -crop ${dims}+0+0 \) +swap -composite  png32:${outputPNG}


#Global
if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then
    # Le metemos el efecto de luz
    ${COMPOSITE} ${outputPNG} ${TMPDIR}/difu.png   png32:${outputPNG}
    # Le metemos un fondo oscuro
    ${CONVERT}   -size ${xsize}x${ysize} xc:"rgb(20,20,20)"  \( ${tmpPNG} -transparent black \) -compose DstOut -composite\
     -transparent black  ${outputPNG} -compose over  -composite   png32:${outputPNG}
fi


# Fondo antes de añadirle el mar
cp ${outputPNG} ${outputsmPNG}

# Fronteras en blanco
${CONVERT} ${outputsmPNG} \( +clone -flatten -negate  \) +swap -composite -threshold 98% -transparent black png32:${outputbwPNG}

# Si había región seleccionada solapamos la fronteras de los continenes con la de la región
if [ ! -z ${cod} ]
then
    ${COMPOSITE} ${outputbwPNG} ${fronterasPNG} png32:${outputbwPNG}
fi

# Fronteras en negro
${CONVERT} ${outputbwPNG} -negate png32:${outputbbPNG}

# Le añadimos el fondo del mar
${COMPOSITE} ${outputPNG} ${fondomar} png32:${outputPNG}


if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then

    # Le aplicamos el efecto de sombra de la tierra para quede más tridimensional
    if [ ! -z ${sombratierra} ] && [  ${sombratierra} -eq 1 ]
    then

        # Si no coincide npulgadas*dpi con el tamaño X o Y de la imagen hay que redimensionar la sombra teniendolo en cuenta
        xsizereal=`awk -v xlength=${xlength} -v cm2inch=${cm2inch} -v dpi=${dpi} 'BEGIN{printf "%d\n",int(xlength*cm2inch*dpi+0.5)}'`
#        ysizereal=`awk -v ylength=${ylength} -v cm2inch=${cm2inch} -v dpi=${dpi} 'BEGIN{printf "%d\n",int(ylength*cm2inch*dpi+0.5)}'`

        # Desplazamiento x de la sombra según el xsize calculado antes
        dx=`awk -v xlength=${xlength} -v cm2inch=${cm2inch} -v dpi=${dpi} -v xsize=${xsize} \
        'BEGIN{printf "%d\n",int((xsize - xlength*cm2inch*dpi)/2)}'`
        # Desplazamiento y de la sombra según el xsize calculado antes
        dy=`awk -v ylength=${ylength} -v cm2inch=${cm2inch} -v dpi=${dpi} -v ysize=${ysize} \
        'BEGIN{dy=int((ysize - ylength*cm2inch*dpi)/2); printf "%d\n",dy-1}'`

        # Tamaño en pixeles que va a tener la sombra
        sombrasize=`awk -v xlength=${xlength} -v xlengthamp=${xlengthamp} -v xsize=${xsizereal} 'BEGIN{print int(xlengthamp*xsize/xlength+0.5)}'`
        # Pixeles que vamos a recortar a la sombra por arriba
        dy=`awk -v dy=${dy} -v ysombrasize=${sombrasize} -v ysize=${ysize} -v ydes=${ydesinicial} \
        'BEGIN{print int((ysombrasize-ysize)/2+0.5)+ydes+dy}'`
        # Pixeles que vamos a recortar a la sombra por la izquierda
        dx=`awk -v dx=${dx} -v xsombrasize=${sombrasize} -v xsize=${xsize} -v xdes=${xdesinicial} \
        'BEGIN{print int((xsombrasize-xsize)/2+0.5)-xdes+dx}'`
        # Si dx o dy es negativo no hay que recortar, hay que desplazar la sombra
        geometry=`awk -v dx=${dx} -v dy=${dy} 'BEGIN{printf "+%d+%d\n",dx<0?-dx:0,dy<0?-dy:0}'`

        # Hacemos el redimensionado, el recorte y el desplazamiento para que la sombra cuadre con la posición y tamaño del planeta
        ${CONVERT} -size ${xsize}x${ysize} xc:white\
         \( ${filesombra} -resize ${sombrasize} -crop ${xsize}x${ysize}+${dx}+${dy} \)\
          -geometry ${geometry} -composite png32:${tmpPNG}

        cp ${tmpPNG} ${outputSombraPNG}

        # Aplicamos la sombra
        ${CONVERT} ${tmpPNG} ${outputPNG} -compose multiply -composite png32:${outputPNG}
    fi

fi

printMessage "Generando fichero de configuración"
writeGeogCFG > ${cfgFile}


# Copiamos los archivos finales
cp -f ${outputPNG} ${outputFinalPNG}
cp -f ${outputsmPNG} ${outputFinalsmPNG}
cp -f ${outputbwPNG} ${outputFinalbwPNG}
cp -f ${outputbbPNG} ${outputFinalbbPNG}
if [ -f ${outputSombraPNG} ]; then cp -f ${outputSombraPNG} ${outputFinalSombraPNG}; fi


printMessage "¡Se han generado los mapas con exito!"


rm -rf ${TMPDIR}; rm -f ${outputPS}
