#!/bin/bash
###############################################################################
# Script que genera un vídeo con una animación en base a unas variables y un
# mapa de fondo seleccionados.
# Se generan 1 archivos en formato de vídeo.
#
#
# Uso:
# animacion.sh tipo fechainicio fechafinal [-f archivo] [-t titulo] [-d fechapasada] [-g geogcfgfile]
#                   [-e stylecfgfile] [-v viento] [-p presion] [-m minutos] [-s slowmotion] [-o] [-h]
#                   [--nstart_frames nsframes] [--nend_frames neframes] [--nframes nframes] [--fadein fadein]
#                   [--border color] [--transparency t] [--bottom_scale bs] [--top_scale ts]
#                   [--show_vars] [--bottom_wind valor] [--presscfg filepress] [--labels filelabels]
#                   [--geoglabels]"
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      04/10/2018
###############################################################################

# Nombre del script.
scriptName=`basename $0`


# Función que define la ayuda sobre este script.
function usage() {

      tiposvideo=`ls ${CFGDIR} | awk 'NR>1{printf ",%s ",var}{"basename "$1" .cfg" |  getline var; }END{printf "y %s\n",var}' | sed 's/^,//'`
      echo
      echo "Genera un vídeo con una animación basada en las variables de los grids."
      echo
      echo "Uso:"
      echo "${scriptName} tipo fechainicio fechafinal [-f archivo] [-t titulo] [-d fechapasada] [-g geogcfgfile]"
      echo "                   [-e stylecfgfile] [-v viento] [-p presion] [-m minutos] [-s slowmotion] [-o] [-h]"
      echo "                   [--nstart_frames nsframes] [--nend_frames neframes] [--nframes nframes] [--fadein fadein]"
      echo "                   [--border color] [--transparency t] [--bottom_scale bs] [--top_scale ts]"
      echo "                   [--show_vars] [--bottom_wind valor] [--presscfg filepress] [--labels filelabels] "
      echo "                   [--geoglabels]"
      echo
      echo " tipo :           Tipo de vídeo que se va a generar. Se pueden configurar los tipos de vídeo en el directorio"
      echo "                  ${CFGDIR}. Los tipos disponibles actualmente son:"
      echo "                  ${tiposvideo}"
      echo " fechainicio :    Fecha en la que comienza la animación del vídeo. En formato yyyyMMddhh (UTC)."
      echo " fechafinal :     Fecha en la que finaliza la animación del vídeo. En formato yyyyMMddhh (UTC)."
      echo " -f archivo:      Nombre del fichero de salida. Por defecto out.mkv"
      echo " -t titulo:       Título que aparecerá en los rótulos del vídeo. Por defecto es el que viene configurado con"
      echo "                  el tipo del vídeo."
      echo " -d fechapasada:  Fecha de la pasada de la que se van a coger los grids de entrada. Por defecto se coge la"
      echo "                  última pasada disponible que sea menor que la fecha de inicio. En formato yyyyMMddhh (UTC)."
      echo " -g geogcfgfile:  Fichero de configuración geográfica. Se pueden generar con el script MapaBase3.sh."
      echo "                  Por defecto spain3.cfg."
      echo " -e stylecfgfile: Fichero de configuración de estilo. Configuración de los elementos que se van a mostrar en "
      echo "                  en el vídeo. Por defecto meteored2.cfg"
      echo " -v viento:       Indica si se van a mostrar las partículas del viento o no. Por defecto viene determinado por"
      echo "                  la configuración de tipo. Puede ser 0 para deshabilitar y 1 para habilitarlo."
      echo " -p presión:      Indica si se va a mostrar las isobaras y las letras de presión. Por defecto viene determinado por"
      echo "                  la configuración de tipo. Puede ser 0 para deshabilitar y 1 para habilitarlo."
      echo " -m minutos:      Minutos en los que se interpola un frame. Debe ser un divisor de 60. Un valor menor hace "
      echo "                  que la animación haga una transición más suave pero la generación del vídeo será más lenta. Por "
      echo "                  defecto viene determinado por la configuración de tipo."
      echo " -s slowmotion:   Factor de ralentización de la animación. Debe ser un entero mayor o igual que 1. El valor 1 "
      echo "                  no altera el número de frames generados en la animación, el valor 2 duplica el número de frames "
      echo "                  generados y el valor n multiplica por n el número de frames. Por defecto viene determinado "
      echo "                  por la configuración de tipo."
      echo " --nstart_frames nsframes: Número de frames desde el comienzo hasta que empieza a moverse la animación. Debe ser "
      echo "                  un número entero entre 1 y 60 y no menor que el valor 'fadein'. Por defecto viene determinado en "
      echo "                  el fichero de configuración de estilo."
      echo " --nend_frames neframes: Número de frames desde que termina la animación hasta que finaliza el vídeo. Debe ser "
      echo "                  un número entero entre 0 y 60. Por defecto viene determinado es 10. "
      echo " --nframes nframes: Número mínimo de frames en cada intervalo de 3 horas. Por defecto es slowmotion*180/minutos. Si  "
      echo "                  se indica un valor mayor se detendrá la animación en la tercera hora hasta que se complete el "
      echo "                  número de frames. Si se han activado las partículas de viento estas seguirán moviendose."
      echo " --fadein fadein: Número de frames que va a durar el efecto de transición entre el mapa base vacio "
      echo "                  y el mapa con variables. Debe ser un valor entre 0 y 60. Si se indica un valor de 0 las variables "
      echo "                  aparecen pintadas desde el principio. Por defecto es 15."
      echo " --border color:  Color de las fronteras del mapa: 'white' para fronteras de color blanco y 'black' para fronteras "
      echo "                  de color negro. Por defecto viene determinado por la configuración de tipo."
      echo " --transparency t:  Porcentaje de transparencia sobre las capas de variables. Por defecto es 0."
      echo " --bottom_scale bs: Valor mínimo de la escala de colores. Para una variable los valores por debajo de este valor no se pintarán "
      echo "                  (transparente). 'bs' tiene el formato 'V0/V1/.../Vn-1' donde 'n' es el número de variables que se van a pintar. "
      echo "                  Vx representa el valor de la variable en la posición x. Por defecto viene determinado por la configuración"
      echo "                  del tipo."
      echo " --top_scale ts:  Valor máximo de la escala de colores. Para una variable los valores por encima de este valor no se pintarán "
      echo "                  (transparente). 'ts' tiene el formato 'V0/V1/.../Vn-1' donde 'n' es el número de variables que se van a pintar. "
      echo "                  Vx representa el valor de la variable en la posición x. Por defecto viene determinado por la configuración"
      echo "                  del tipo."
      echo " --show_vars:     Muestra las variables que se van a pintar ordenadas de abajo a arriba."
      echo " --bottom_wind valor: Valor mínimo del viento. Por debajo de este valor no se pintarán las partículas del viento. Por defecto "
      echo "                  viene determinado en la configuración del tipo."
      echo " --presscfg filepress: Fichero de configuración de presión. Utilizará la configuración de presión especificada en el fichero. Se"
      echo "                  puede generar con el script presslabels.sh."
      echo " --labels filelabels: Fichero de trayectoria de etiquetas. Pintará las etiquetas definidas en este fichero. Se puede generar"
      echo "                  generar con el script labels.sh."
      echo " --geoglabels:    Indica si las coordenadas definidas en el fichero de etiquetas son geográficas. Si no se usa esta opción"
      echo "                  se tomarán como cartesianas."
      echo " -o:              Sobreescribe todos los ficheros sin preguntar si existen."
      echo " -h:              Muestra esta ayuda."
      echo
      echo "El fichero default.cfg define las variables de configuración de este comando."

}

# Parsea los argumentos pasados al comando a través de la línea de comandos
function parseOptions() {
    OVERWRITE=0

    if [ $# -eq 0 ]
    then
       echo "Error: el número de argumentos mínimo es 3" >&2; usage; exit 1
    fi

    if [ $1 != "-h" ]
    then
        if [ $# -lt 3 ]
        then
           echo "Error: el número de argumentos mínimo es 3" >&2; usage; exit 1
        fi

        # Expresiones regulares
        refloat="^[+-]?[0-9]+([.][0-9]+)?$"
        reint="^[+-]?[0-9]+$"
        repos="^[0-9]+$"
        refecha="^[0-9]{10}$"
        rebin="^[0-1]{1}$"


        # Chequeamos el tipo
        tipo=$1;
        [ ! -f ${CFGDIR}/${tipo}.cfg ] && { echo "Error: no existe el tipo ${tipo}" >&2; usage; exit 1; }
        shift;

        # Chequeamos la fecha de inicio
        min=$1
        min=`date -u -d "${min:0:8} ${min:8:2}" +%Y%m%d%H00 2> /dev/null`


        [ $? -ne 0 ] || ! [[ $1 =~ ${refecha} ]] && { echo "Error: la fecha inicial $1 no tiene formato correcto" >&2; usage; exit 1; }
        shift;

        # Chequeamos la fecha de fin
        max=$1
        max=`date -u -d "${max:0:8} ${max:8:2}" +%Y%m%d%H00 2> /dev/null`

        [ $? -ne 0 ] || ! [[  $1 =~ ${refecha} ]] && { echo "Error: la fecha final $1 no tiene formato correcto" >&2; usage; exit 1; }
        shift;

        [ ${max} -le ${min} ] && { echo "Error: la fecha final debe ser mayor que la fecha inicial" >&2; usage; exit 1; }

    fi


    # Chequeamos el resto de opciones
    options=$(getopt -o hf:t:d:g:e:v:p:m:s:o --long nend_frames: --long nstart_frames: --long nframes: --long fadein:\
     --long border: --long bottom_scale: --long top_scale: --long show_vars --long transparency: --long bottom_wind: \
     --long presscfg: --long pressexclude: --long labels: --long geoglabels -- "$@")

    if [ $? -ne 0 ]
    then
        usage; exit 1
    fi


    # set -- opciones: cambia los parametros de entrada del script por los especificados en opciones y en ese orden. la opción "--"
    # hace que tenga en cuenta tambien los argumentos que empiezan por "-" (sino los omite).
    eval set -- "${options}"

    while true; do
        case "$1" in
        -f)
            shift
            outputFile=$1
            ;;
        -t)
            shift
            tituloParam=$1
#            echo $titulo
            ;;
        -d)
            shift
            fechapasadaParam=$1
            fechapasadaParam=`date -u -d "${fechapasadaParam:0:8} ${fechapasadaParam:8:2}" +%Y%m%d%H00 2> /dev/null`
            [ $? -ne 0 ] || ! [[  $1 =~ ${refecha} ]] && \
                { echo "Error: la fecha de pasada $1 no tiene formato correcto" >&2; usage; exit 1; }
            [ ${fechapasadaParam} -gt ${min} ] && \
                { echo "Error: la fecha de pasada debe ser menor o igual que la fecha inicial" >&2; usage; exit 1; }
            [ ! -d "${DIRNETCDF}/${fechapasadaParam:0:10}" ] && \
                { echo "Error: No existe un directorio para la fecha de pasada ${fechapasadaParam}" >&2; usage; exit 1; }
            ;;
        -g)
            shift
            geogfile="${GEOGCFGDIR}/$1"

            ;;
        -e)
            shift
            stylefile=${DIRESTILOS}/$1
            ;;
        -v)
            shift
            pintarVientoParam=$1
            ! [[ ${pintarVientoParam} =~ ${rebin} ]] && \
                { echo "Error: El valor viento debe ser 0 o 1." >&2; usage; exit 1; }
            ;;
        -p)
            shift
            pintarPresionParam=$1
            ! [[ ${pintarPresionParam} =~ ${rebin} ]] && \
                { echo "Error: El valor presión debe ser 0 o 1." >&2; usage; exit 1; }
            ;;
        -m)
            shift
            minsParam=$1
            ! [[ ${minsParam} =~ ${repos} ]] || [ $(( 60 % ${minsParam} )) -ne 0 ] && \
                { echo "Error: El valor mins debe entero positivo y divisor de 60." >&2; usage; exit 1; }
            ;;
        -s)
            shift
            slowmotionParam=$1
            ! [[ ${slowmotionParam} =~ ${repos} ]] || [ ${slowmotionParam} -lt 1 ] && \
                { echo "Error: El valor slowmotion debe entero positivo y mayor que 1." >&2; usage; exit 1; }
            ;;
        --nstart_frames)
            shift
            nframesloopParam=$1
            ! [[ ${nframesloopParam} =~ ${repos} ]] || [ ${nframesloopParam} -lt 1 ]|| [ ${nframesloopParam} -gt 60 ] && \
            { echo "Error: El valor --nstart_frames debe entero positivo entre 1 y 60." >&2; usage; exit 1; }
            ;;
        --nend_frames)
            shift
            nframesfinalParam=$1
            ! [[ ${nframesfinalParam} =~ ${repos} ]] || [ ${nframesfinalParam} -gt 600 ] && \
            { echo "Error: El valor --nend_frames debe entero positivo entre 0 y 120." >&2; usage; exit 1; }
            ;;
        --nframes)
            shift
            nframesParam=$1
            ! [[ ${nframesParam} =~ ${repos} ]] || [ ${nframesParam} -lt 1 ] || [ ${nframesParam} -gt 60 ] && \
            { echo "Error: El valor --nframes debe entero positivo entre 1 y 60." >&2; usage; exit 1; }
            ;;
        --fadein)
            shift
            fadeinParam=$1
            ! [[ ${fadeinParam} =~ ${repos} ]] || [ ${fadeinParam} -gt 60 ] && \
            { echo "Error: El valor --fadein debe entero positivo entre 0 y 60." >&2; usage; exit 1; }
            ;;
        --border)
            shift
            borderParam=${1,,}
            [ ${borderParam} != "black" ] && [ ${borderParam} != "white" ] && \
            { echo "Error: El valor --border debe ser 'black' o 'white' ." >&2; usage; exit 1; }
            ;;
        --show_vars)
            shift
            SHOWVARS=1
            break;
            ;;
        --bottom_scale)
            shift
            bottomscale=(`echo $1 | tr "/" " "`)
            ;;
        --top_scale)
            shift
            topscale=(`echo $1 | tr "/" " "`)
            ;;
        --bottom_wind)
            shift
            bottomwindParam=$1
            ! [[ ${bottomwindParam} =~ ${refloat} ]] || [ ${bottomwindParam} -lt 0 ] && \
            { echo "Error: El valor --bottomwind debe ser un valor real mayor o igual que 0." >&2; usage; exit 1; }
            ;;
        --transparency)
            shift
            transparency=$1
            ! [[ ${transparency} =~ ${repos} ]] || [ ${transparency} -gt 100 ] && \
            { echo "Error: El valor --transparency debe ser un valor positivo entre 0 y 100." >&2; usage; exit 1; }
            ;;
        --presscfg)
            shift
            presscfgfile=$1
            ;;
        --labels)
            shift
            labelsfile=$1
            pintarEtiquetas=1
            [ ! -f ${labelsfile} ] && \
            { echo "Error: El fichero ${labelsfile} no existe." >&2; usage; exit 1; }
            ;;
        --geoglabels)
            shift
            geoglabels=1
            ;;

        -o)
            OVERWRITE=1
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

#### Variables por defecto

# Si se pintan o no las partículas de viento
pintarViento=1
# Si se pintan o no las variables
pintarIntensidad=1
# Si se pintan o no las isobaras
pintarPresion=1
# Titulo del vídeo
titulo="Mi video"
# Minutos en los que se genera cada frame
mins=30
# Número de horas en las que cambia el viento
stepviento=3
# Número de horas en las que cambian los rotulos
steprotulo=1
# Factor de ralentización de la animación
slowmotion=2
# Número mínimo de frames cada 3 horas
nframes=1
# Número de frames de la transicción del mapa vacío hasta que aparecen las variables
fadein=15
# Si se inserta al final del vídeo una animación con rotulos de una variable
pintarAnotacionesFinal=0
# Color de las anotaciones del final del vídeo
colorAnotacion="white"
# Número de frames desde que termina la animación hasta el final del vídeo
nframesfinal=10
# Umbral a partir del cual no se va a pintar precipitación por debajo de él
umbralPREC=0.5


#### Variables de isobaras

# Color de las isobaras
colorisobaras="white"
# Distancia entre isobaras
disobaras=5
# Distancia entre etiquetas. No se usa
detiquetas=5
# Umbral de presión para considerar puntos de baja y alta presión
normalmsl=1013
# Se usa para calcular lmsl y hmsl
rango=2
# Umbral por el que por debajo los mínimos locales se considerán puntos de Baja Presión
lmsl=$((${normalmsl}-${rango}))
# Umbral por el que por encima los máximos locales se considerán puntos de Alta Presión
hmsl=$((${normalmsl}+${rango}))
# Resolución a la que se resamplea la presión (y otras variables)
presres=0.5
# Factor de suavizado para presión (y otras variables)
pressmooth=19


#### Variables de las partículas de viento

# Si se va a pintar la escala de viento o no
escalaViento=0
# CPT de colores con los que se van a pintar las partículas
cptViento="${CPTDIR}/v10m_201404.cpt"
#cptViento="white"
# Edad máxima en frames para una partícula
max_age=50
# Densidad de partículas por cm
dparticulas=50
# Número total de partículas
nparticulas=`awk -v w=${xlength} -v n=${dparticulas} 'BEGIN{printf "%d",w*n}'`
# Factor de difuminado de las partículas.
# Cuanto más alto menos estela deja.
fade=7.5
# Factor de la longitud de las partículas. Se autoajusta en función de las dimensiones del
scale=400
# Nombre por defecto del fichero de salida
outputFile="out.mkv"


#### Variables de etiquetas

# Si se pintan etiquetas generadas por el usuario
pintarEtiquetas=0
# Las coordenadas de las etiquetas son geográficas (1) o cartesianas (0)
geoglabels=0

# Comprobación de que existe el software.
command -v ${GMT} > /dev/null 2>&1 || { echo "error: ${GMT} no está instalado." >&2 && exit 1; }
command -v ${CONVERT}  > /dev/null 2>&1 || { echo "error: ${CONVERT} no está instalado." >&2 && exit 1; }
command -v ${COMPOSITE}  > /dev/null 2>&1 || { echo "error: ${COMPOSITE} no está instalado." >&2 && exit 1; }
command -v ${FFMPEG}  > /dev/null 2>&1 || { echo "error: ${FFMPEG} no está instalado." >&2 && exit 1; }
command -v ${OGR2OGR}  > /dev/null 2>&1 || { echo "error: ${OGR2OGR} no está instalado." >&2 && exit 1; }
command -v ${CDO}  > /dev/null 2>&1 || { echo "error: ${CDO} no está instalado." >&2 && exit 1; }

parseOptions "$@"

checkDIRS

# Si no se ha pasado archivo de conf geográfico o de estilo por parámetro se cogen estos por defecto
[ -z ${geogfile} ] && geogfile="${GEOGCFGDIR}/spain3.cfg"
[ -z ${stylefile} ] && stylefile="${DIRESTILOS}/meteored2.cfg"

# Comprobamos que existen los ficheros de configuración
[ ! -f "${geogfile}" ] && \
    { echo "Error: No existe el fichero de configuración geográfica ${geogfile}" >&2; usage; exit 1; }
[ ! -f "${stylefile}" ] && \
{ echo "Error: No existe el fichero de configuración de estilo ${stylefile}" >&2; usage; exit 1; }

source ${geogfile}
source ${stylefile}

# Comprobamos que existen los frames del cartel del título
if [ -d `dirname ${framescartel}` ]
then
    nframescartel=$(ls `dirname ${framescartel}` | egrep "`basename ${framescartel} | sed 's/%0\(.\)d/[0-9]{\1}/'`" | wc -l)
    [ ${nframescartel} -eq 0 ] && \
        { echo "Error: No hay frames disponibles para el cartel de rótulos en `dirname ${framescartel}`" >&2; usage; exit 1; }
else
    echo "Error: No se ha encontrado el directorio `dirname ${framescartel}`" >&2
    usage
    exit 1;
fi

# Comprobamos que existen las fuentes del titulo y subtitulo
[ `${CONVERT} -list font | sed -n '/^[[:space:]]*Font:[[:space:]]*'${fuentetitulo}'$/Ip' | wc -l` -eq 0 ] &&\
    { echo "Error: No se ha encontrado la fuente ${fuentetitulo}" >&2; usage; exit 1; }
[ `${CONVERT} -list font | sed -n '/^[[:space:]]*Font:[[:space:]]*'${fuentesubtitulo}'$/Ip' | wc -l` -eq 0 ] &&\
    { echo "Error: No se ha encontrado la fuente ${fuentesubtitulo}" >&2; usage; exit 1; }

# Comprobamos que existen los logos
for((nlogo=0; nlogo<${nlogos}; nlogo++))
do
    [ ! -f ${logo[${nlogo}]} ] &&
        { echo "Error: No se ha encontrado el logo ${logo[${nlogo}]}" >&2; usage; exit 1; }
done

# Chequeamos los archivos del fichero de configuración geográfica
[ ! -z ${GLOBEFILE} ] && [ ! -f ${GLOBEFILE} ] && \
    { echo "Error: No se ha encontrado el fichero ${GLOBEFILE}" >&2; usage; exit 1; }
[ ! -f ${fondomar} ] && \
    { echo "Error: No se ha encontrado el fichero ${fondomar}" >&2; usage; exit 1; }
[ ! -f ${fronterasPNG} ] && \
    { echo "Error: No se ha encontrado el fichero ${fronterasPNG}" >&2; usage; exit 1; }
[ ! -f ${fondoPNG} ] && \
    { echo "Error: No se ha encontrado el fichero ${fondoPNG}" >&2; usage; exit 1; }
[ ! -z ${fronterasPNGw} ] && [ ! -f ${fronterasPNGw} ] && \
    { echo "Error: No se ha encontrado el fichero ${fronterasPNGw}" >&2; usage; exit 1; }
[ ! -z ${fronterasPNGb} ] && [ ! -f ${fronterasPNGb} ] && \
    { echo "Error: No se ha encontrado el fichero ${fronterasPNGb}" >&2; usage; exit 1; }


# Calculamos la longitud cartesiana y en cms. Si es global, depende de los pixeles de x e y. Si no lo es,
# la sacamos con mapproject.
if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then
    ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`
else
    ylength=`${GMT} mapproject ${J} ${R} -W | awk '{print $2}'`
fi

# Ajusta la escala a las dimensiones del mapa
# Tomamos como buena la escala de 400 en las dimensiones del mapa de España (0.00596105)
read w h < <(${GMT} mapproject ${J} ${R} -W)
scale=`awk -v w=${w} -v h=${h} 'BEGIN{printf "%.2f %.2f 1 1\n",w/2,h/2}' | ${GMT} mapproject ${J} ${R} -I |\
awk -v scale=${scale} -f newlatlon.awk | awk '{print $1,$2; print $3,$4}' | ${GMT} mapproject ${J} ${R} |\
 awk -v scale=${scale} 'NR==1{x1=$1; y1=$2}NR==2{print 0.00596105/sqrt(($1-x1)^2+($2-y1)^2)*scale}'`




# Cogemos el directorio de pasada con fecha más actualizada que sea menor que el mínimo
fechapasada="`find ${DIRNETCDF}/ -maxdepth 1 -mindepth 1 -type d | awk '{system("basename "$1)}' |  egrep "[0-9]{10}" | sort -n | \
 awk -v min=${min:0:10} '$1<=min' | tail -n 1`00"

# Si no se encuentra ningun directorio de pasada
[ ${fechapasada} == "00" ] && \
    { echo "Error: No se ha encontrado ningún directorio de pasada en ${DIRNETCDF}" >&2; usage; exit 1; }

# Si el directorio de pasada pasa el patrón de 10 digitos pero no es una fecha válida
date -d "${fechapasada:0:8} ${fechapasada:8:2}" > /dev/null 2>&1 || \
    { echo "Error: el directorio ${fechapasada:8:10} no corresponde con una fecha válida" >&2; usage; exit 1; }


# mínimo real especificado por el usuario
minreal=${min}
# Si min no es multiplo de 3, se asigna a min el múltiplo de 3 más cercano
min=${minreal:0:8}`printf "%02d" $(( $(echo ${min:8:2}|awk '{print int($0)}')/3*3 ))`00
# Diferencia entre el minimo real y el minimo
desfasemin=$((${minreal:0:10}-${min:0:10}))





# Cargamos las variables según el tipo seleccionado
source cfg/${tipo}.cfg

# Si se ha seleccionado la opción --showvars, mostramos las variables y salimos
[ ! -z ${SHOWVARS} ] && [ ${SHOWVARS} -eq 1 ] &&
    { echo "${variablesanimacion[*]}"; exit 0; }

# Modificamos las variables según los parámetros pasados
[ ! -z "${tituloParam}" ] && titulo="${tituloParam}"
[ ! -z ${pintarVientoParam} ] && pintarViento=${pintarVientoParam}
[ ! -z ${pintarPresionParam} ] && pintarPresion=${pintarPresionParam}
[ ! -z ${minsParam} ] && mins=${minsParam}
[ ! -z ${slowmotionParam} ] && slowmotion=${slowmotionParam}
[ ! -z ${nframesfinalParam} ] && nframesfinal=${nframesfinalParam}
[ ! -z ${nframesloopParam} ] && nframesloop=${nframesloopParam}
[ ! -z ${nframesParam} ] && nframes=${nframesParam}
[ ! -z ${fadeinParam} ] && fadein=${fadeinParam}
[ ! -z ${fechapasadaParam} ] && fechapasada=${fechapasadaParam}
[ ! -z ${bottomwindParam} ] && bottomwind=${bottomwindParam}

# Si se ha especificado un valor de transparencia lo normalizamos a un valor de 0 a 1
[ ! -z ${transparency} ] && transparency=`awk -v t=${transparency} 'BEGIN{printf "%.4f",1-t/100}'`

# Si en la configuración del tipo se ha indicado el color blanco
if [ ! -z ${colorfronteras} ] && [ ${colorfronteras} == "white" ]
then
    fronterasPNG=${fronterasPNGw}
fi

# Si por parámetro se especifica un color se fuerza
if [ ! -z ${borderParam} ]
then
    if [ ${borderParam} == "black" ]
    then
        fronterasPNG=${fronterasPNGb}
    else
        fronterasPNG=${fronterasPNGw}
    fi
fi



# Si el valor de frames fadein es mayor que los frames de inicio
[ ${fadein} -gt ${nframesloop} ] && \
{ echo "Error: El valor --fadein (${fadein}) no puede ser mayor que el valor --nstart_frames (${nframesloop})." >&2; usage; exit 1; }


# Si el cfg del tipo se especifica un desfase distinto de 0 ajustamos el mínimo real a ese desfase.
# Por ejemplo en precipitación prevista
if [ ${minreal} -eq ${min} ] && [ ${desfasemin} -ne 0 ]
then
    minreal=`date -u -d "${min:0:8} ${min:8:4} +${desfasemin} hours" +%Y%m%d%H00`
fi

# Número de saltos de 3 horas entre la fecha de inicio y la de fin
nsteps=$(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(3600*3) ))
# Si min es distinto de minreal los saltos de horas del inicio son de menos de 3 horas. Calculamos ese número
# de saltos con menos de 3 horas
[ ${nsteps} -ge 1 ] && nstepsinicio=2 || nstepsinicio=1
nsteps=$((${nsteps}-${nstepsinicio}+1))


# Número de frames de los saltos del principio
nframesinicio=${nframes}

if [ ${nframesinicio} -lt $((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins})) ]
then
    nframesinicio=$((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins}))
fi

if [ ${nframes} -lt $((${slowmotion}*180/${mins})) ]
then
    nframes=$((${slowmotion}*180/${mins}))
fi

# Frame donde finaliza la animación
nframefinal=$((${nsteps}*${nframes}+${nframesloop}+${nframesinicio}*${nstepsinicio}))

# Chequeamos que los valores especificados en bottomscale tienen el formato correcto
refloat="^[+-]?[0-9]+([.][0-9]+)?$"
if [ ${#bottomscale[*]} -gt 0 ] && [ ${#bottomscale[*]} -le ${#variablesanimacion[*]} ]
then
    for ((i=0;i<${#variablesanimacion[*]};i++))
    do
        if [ ${i} -lt ${#bottomscale[*]} ]
        then
            ! [[ ${bottomscale[${i}]}  =~ ${refloat} ]] && [ ${bottomscale[${i}]^^}  != "N" ] &&
            { echo "Error: El parámetro ${bottomscale[${i}]} no tiene un formato correcto" >&2; usage; exit 1; }
        else
            bottomscale[${i}]="N"
        fi
    done
elif [ ${#bottomscale[*]} -gt 0 ]
then
    echo "Error: El número de parámetros pasados a la opción --bottom_scale no puede ser superior que el número de variables" >&2;
    usage;
    exit 1;
fi

# Chequeamos que los valores especificados en topscale tienen el formato correcto
if [ ${#topscale[*]} -gt 0 ] && [ ${#topscale[*]} -le ${#variablesanimacion[*]} ]
then
    for ((i=0;i<${#variablesanimacion[*]};i++))
    do
        if [ ${i} -lt ${#topscale[*]} ]
        then
            ! [[ ${topscale[${i}]}  =~ ${refloat} ]] && [ ${topscale[${i}]^^}  != "N" ] &&
            { echo "Error: El parámetro ${topscale[${i}]} no tiene un formato correcto" >&2; usage; exit 1; }
        else
            topscale[${i}]="N"
        fi
    done
elif [ ${#topscale[*]} -gt 0 ]
then
    echo "Error: El número de parámetros pasados a la opción --top_scale no puede ser superior que el número de variables" >&2;
    usage;
    exit 1;
fi

# Indica si se calcularán los máximos y mínimos de presión o se cogeran del fichero
calcularMaxMinPress=1
if [ ! -z ${presscfgfile} ]
then
    pintarPresion=1

    # Chequeamos que las opciones que vienen en el fichero de configuración de presión coinciden
    # con las opciones que hemos pasado a los parámetros
    [ ! -f ${presscfgfile} ] && \
        { echo "Error: No se ha encontrado el fichero ${presscfgfile}" >&2; usage; exit 1; }
    [ `sed -n '1p' ${presscfgfile}` != "press" ] && \
        { echo "Error: La variable del fichero ${presscfgfile} tiene que ser 'press'" >&2; usage; exit 1; }
    [ `sed -n '2p' ${presscfgfile}` -ne ${fechapasada} ] && \
        { echo "Error: La fecha de pasada del fichero ${presscfgfile} es distinta que la especificada" >&2; usage; exit 1; }
    [ ${min} -ne `sed -n '3p' ${presscfgfile} | awk '{print $1}'` ] && \
        { echo "Error: El mínimo definido en ${presscfgfile} es didtinto al especificado" >&2; usage; exit 1; }
    [ ${max} -ne `sed -n '3p' ${presscfgfile} | awk '{print $2}'` ] && \
        { echo "Error: El máximo definido en ${presscfgfile} es didtinto al especificado" >&2; usage; exit 1; }
    [ ${mins} -ne `sed -n '4p' ${presscfgfile}` ] && \
        { echo "Error: El valor mins definido en ${presscfgfile} es distinto al especificado" >&2; usage; exit 1; }
    [ ${geogfile} != `sed -n '5p' ${presscfgfile}` ] && \
        { echo "Error: El fichero de configuración geográfica definido en ${presscfgfile} es distinto al especificado " >&2; usage; exit 1; }

    presres=`sed -n '6p' ${presscfgfile}`
    ! [[ ${presres} =~ ${refloat} ]] || (( `echo "${presres} <  0 " | bc -l` )) && \
        { echo "Error: El valor preres de ${presscfgfile} tiene que ser real mayor que 0" >&2; usage; exit 1; }

    umbralPress=`sed -n '7p' ${presscfgfile}`
    ! [[ ${umbralPress} =~ ${refloat} ]] || (( `echo "${umbralPress} <  0 " | bc -l` )) && \
        { echo "Error: El valor umbralpress de ${presscfgfile} tiene que ser real mayor que 0" >&2; usage; exit 1; }

    pressmooth=`sed -n '8p' ${presscfgfile}`
    ! [[ ${pressmooth} =~ ${repos} ]] || [ ${pressmooth} -le 0 ] || [ $(( ${pressmooth} % 2 )) -eq 0 ] && \
        { echo "Error: El valor pressmooth de ${presscfgfile} tiene que ser positivo impar mayor que 0" >&2; usage; exit 1; }

    nminframesMSL=`sed -n '9p' ${presscfgfile}`
    ! [[ ${nminframesMSL} =~ ${repos} ]]  && \
        { echo "Error: El valor nminframesMSL de ${presscfgfile} tiene que ser positivo" >&2; usage; exit 1; }

    calcularMaxMinPress=0
else

    # Determina como de cerca tiene que estar un punto de baja o alta presión, entre frames, para considerarse que es el mismo
    # En cms
    umbralPress=`awk -v w=${w} -v h=${h} 'BEGIN{printf "%.2f %.2f 0 1\n",w/2,h/2}' | ${GMT} mapproject  ${J} ${R} -I |\
      awk -v scale=100 -f newlatlon.awk | awk '{print $1,$2; print $3,$4}' | ${GMT} mapproject ${J} ${R} |\
       awk -v mins=${mins} 'NR==1{x1=$1; y1=$2}NR==2{print mins/30*1000*($2-y1)}'`

#    umbralPress=0.4

    # Número mínimo de frames seguidos que debe aparecer una letra de Baja o Alta presión
    # Está configurado como la mitad de los frames de la animación
    nminframesMSL=$(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(${mins}*60*2) ))
#    nminframesMSL=20

fi
# Establecemos la distancia mínima entre letras como el umbral
dminletras=${umbralPress}




TMPDIR="/tmp"

# Diretorio temporal
TMPDIR=${TMPDIR}/`basename $(type $0 | awk '{print $3}').$$`
#TMPDIR=/tmp/animViento.sh.12766
mkdir -p ${TMPDIR}

# Definimos que el script pare si se captura alguna señal de terminación o se produce algún error
trap "rm -rf ${TMPDIR}; echo 'error: señal interceptada. Saliendo' >&2;exit 1" 1 2 3 15
trap "echo 'error: ha fallado la ejecución. Saliendo' >&2;exit 1" ERR

# Fichero de errores
errorsFile="${TMPDIR}/errors.txt"
touch ${errorsFile}



########## COMIENZO


printMessage "Generando vídeo de tipo ${tipo} desde ${minreal} hasta ${max}"

printMessage "Parámetros: zona geográfica `basename ${geogfile}`, estilo `basename ${stylefile}`, 1 frame cada ${mins} minutos y slowmotion ${slowmotion}."

printMessage "Pintar partículas de viento: ${pintarViento}"
printMessage "Pintar variables: ${pintarIntensidad} -> variables: ${variablesanimacion[*]}"
printMessage "Pintar presión: ${pintarPresion}"

# Guardamos la J y la R geográficas ya que la J y la R iran cambiando entre geográficas y cartesianas
JGEOG=${J}
RGEOG=${R}

# Si estamos pintando rachas de viento comprobamos que existe el grid de las 3 horas siguientes
maxcheck=${max}
[ ! -z ${pintarRachasViento} ] && [ ${pintarRachasViento} -eq 1 ] &&\
 maxcheck=`date -u --date="${max:0:8} ${max:8:2} +3 hours" +%Y%m%d%H%M`

# Chequeamos que existen los grids necesarios para obtener las variables creando un enlace simbólico
checkGrids ${min} ${maxcheck} ${fechapasada}


# Pintamos las variables
if [ ${pintarIntensidad} -eq 1 ]
then
    opcionesEntrada=""
    filtro="[0][1]overlay"
    ivar=0
    # Las variables se pintan en el orden en el que vienen en el array
    for variablefondo in ${variablesanimacion[*]}
    do
        # Usamos la J y R geográficas
        J=${JGEOG}
        R=${RGEOG}

        # Cargamos la configuración de la variable
        cargarVariable ${variablefondo}

        tcolor="none"
        # Recortamos la escala de la variable al valor especificado para esa variable en bottomscale
        [ ${ivar} -lt ${#bottomscale[*]} ] && [ ${bottomscale[${ivar}]} != "N" ] && \
            {
                ${GMT} makecpt -C${cptGMT} -Fr | awk -v umbral=${bottomscale[${ivar}]} '$1~/F|N|B/||$1>=umbral{print $0}' > ${TMPDIR}/bottom.cpt;
                cptGMT="${TMPDIR}/bottom.cpt";
                tcolor=`sed -n '/^B/p' ${cptGMT} | tr "/" "," | awk '{printf "rgb(%s)",$2}'`
            };

        # Recortamos la escala de la variable al valor especificado para esa variable en topscale
        [ ${ivar} -lt ${#topscale[*]} ] && [ ${topscale[${ivar}]} != "N" ] && \
            {

                ${GMT} makecpt -C${cptGMT} -Fr | awk -v umbral=${topscale[${ivar}]} '$1~/F|N|B/||$1<=umbral{print $0}' > ${TMPDIR}/top.cpt;
                cptGMT="${TMPDIR}/top.cpt";
                if [ ${tcolor} == "none" ]
                then
                    tcolor=`sed -n '/^F/p' ${cptGMT} | tr "/" "," | awk '{printf "rgb(%s)",$2}'`
                else
                    # Si ya se ha recortado con bottomscale cambiamos el valor Forward al Below de la escala anterior
                    # para que tenga el mismo color y se haga transparente
                    Bcolor=`sed -n '/^B/p' ${cptGMT} | awk '{print $2}' | sed 's/\//\\\\\//g'`
                    sed "s/^F.*$/F ${Bcolor}/" ${cptGMT} > ${TMPDIR}/kk.cpt
                    mv  ${TMPDIR}/kk.cpt  ${cptGMT}
                fi

            };

        fecha=${min}
        fechamax=${max}

        printMessage "Procesando los grids para la variable '${variablefondo}' desde ${fecha} hasta ${fechamax}"

        variable=${variablefondo}
        nvar=0
        # Procesamos los grids con las variables que necesitemos. Puede ser que haya que procesar más de una variable
        # como en la precipitación con la prec acumulada y la tasa de prec
        for funcion in ${funcionesprocesar}
        do
            # Según la variable puede que el máximo esté limitado, como en la tasa de prec hasta 72 horas
            maxvariable=`date -u --date="${fechapasada:0:8} ${fechapasada:8:2} +${maxalcancevariables[${nvar}]} hours" +%Y%m%d%H%M`
            [ ${maxvariable} -gt ${max} ] && maxvariable=${max};

            if [ ${#variablesprocesar[*]} -gt 0 ]
            then
                 variable=${variablesprocesar[${nvar}]}
                 nvar=$((${nvar}+1))
            fi

            function procesarGrid {
                ${funcion}
            }
            procesarGrids ${variable} ${min} ${maxvariable} ${fechapasada}
        done



        # Usamos las J y R cartesianas
        J="-JX${xlength}c/${ylength}c"
        R=`grdinfo ${dataFileDST} -Ir -C` ####


        stepinterp=3
        # Si estamos pintando una variable de precipitación interpolamos con sus algoritmos
        if [ ! -z ${esprecipitacion} ] && [ ${esprecipitacion} -eq 1 ]
        then

            interpolarPREC ${variablefondo} ${min} ${max} ${fechapasada}
            stepinterp=1

        fi

        # Hacemos interpolación cúbica de los gris
        if [ ${mins} -lt $((${stepinterp}*60)) ]
        then
            interpolarFrames "${variablefondo}" ${min} ${max} ${mins} ${stepinterp}
        fi

        # Generamos los frames a partir de los grids interpolados
        generarFrames "${variablefondo}" ${min} ${max} ${mins} ${tcolor} ${transparency}

        # En imagenes en blanco y negro convertimos uno de sus canales a canal alpha (nubes)
        if [ ! -z ${estransparente} ] && [ ${estransparente} -eq 1 ]
        then
            black2transparentFrames "${variablefondo}"
        fi

        # Replicamos los frames
        replicarFrames "${variablefondo}"

        opcionesEntrada="${opcionesEntrada} -f image2 -i ${TMPDIR}/${variablefondo}%03d.png"
        if [ ${ivar} -gt 0 ]
        then
            filtro="${filtro}[out];[out][$((${ivar}+1))]overlay"
        fi

        ivar=$((${ivar}+1))

    done

    i=0
    # Generamos las escalas que queramos pintar de las variables
    for ivar in ${indexescala[*]}
    do
        variablefondo=${variablesanimacion[${ivar}]}
        cargarVariable ${variablefondo}

        #Calcular maximo y mínimo de todos los grids de la variable
        [ ${ivar} -ge ${#bottomscale[*]} ] || [ ${bottomscale[${ivar}]} == "N" ] || \
        [ ${ivar} -ge ${#topscale[*]} ] || [ ${topscale[${ivar}]} == "N" ] && \
            calcularMinMax "${variablefondo}" ${min} ${max} ${stepinterp}

        # Si se ha especificado un valor en bottomscale se recorta la escala generada a ese valor
        [ ${ivar} -lt ${#bottomscale[*]} ] && [ ${bottomscale[${ivar}]} != "N" ] && \
            zmin=${bottomscale[${ivar}]}

        # Si se ha especificado un valor en topscale se recorta la escala generada a ese valor
        [ ${ivar} -lt ${#topscale[*]} ] && [ ${topscale[${ivar}]} != "N" ] && \
            zmax=${topscale[${ivar}]}

        printMessage "Generando Escala para ${variablefondo} a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"
        P=""
        # Si la escala es horizontal
        if [ ${tipoescala[${i}]} == "h" ]
        then
            P="-p"
        fi
        ./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala${ivar}.png  ${unidadEscala} ${nombresvariables[${ivar}]} 2>> ${errorsFile}

        i=$((${i}+1))

    done



    printMessage "Uniendo los frames de las variables ${variablesanimacion[*]} y superponiendo frontera"
    variablefondo=`echo ${variablesanimacion[*]} | tr " " "-"`
    # Unimos los frames de las variables y le ponemos la frontera
    ${FFMPEG} ${opcionesEntrada} -f image2 -i ${fronterasPNG} -filter_complex ${filtro} -vsync 0 ${TMPDIR}/kk%03d.png 2>> ${errorsFile}
    rename -f "s/kk/${variablefondo}/" ${TMPDIR}/kk*.png
fi


# Pintamos las isobaras
if [ ${pintarPresion} -eq 1 ]
then

    # Usamos la J y R geográficas
    J=${JGEOG}
    R=${RGEOG}

    function procesarGrid {
        procesarPresion
    }
    printMessage "Procesando los grids de Presión (MSL) desde ${fecha} hasta ${fechamax}"

    # Procesamos los grids de presión
    procesarGrids "msl" ${min} ${max} ${fechapasada}

    # Usamos la J y R cartesianas
    J="-JX${xlength}c/${ylength}c"
    R=`grdinfo ${dataFileDST} -Ir -C` ####

    #Redifinimos la función pintarVariable
    function pintarVariable {
        pintarPresion $1
    }

    # Interpolamos los grids
    interpolarFrames "msl" ${min} ${max} ${mins} 3

    generarFrames "msl" ${min} ${max} ${mins} "none" 1

    replicarFrames "msl"

    # Si hemos pasado un fichero de configuración de presión no habrá que volver a hacer el cálculo de máximos y mínimos
    if [ -z ${calcularMaxMinPress} ] || [ ${calcularMaxMinPress} -eq 1 ]
    then
        printMessage "Calculando máximos/mínimos de MSL desde ${min} hasta ${max}"

        # Filtramos los máximos A y lo mínimos B quitando aquellos que aparezcan menos frames de nminframes. Esto evita que aparezcan A y B que aparecen y desaparecen rapidamente
        # 1. Pasamos las coordenadas geográficas a cartesianas
        # 2. Le ponemos un ID a las letras identificando cuales son las mismas entre distintas fechas. Si la distancia entre distintas fechas
        # de dos letras es menor que umbralPress consideramos que es la misma letra
        # 3. Descartamos aquellas que no aparezcan en mas de nminframes consecutivas. Suavizamos también el movimiento de las letras y hacemos
        # que aparezcan y desaparezcan también de forma suave
        paste <(awk '{print $1"\t"$2"\t"$3}' ${TMPDIR}/maxmins.txt) <(awk '{print $2,$3,$4,$5}' ${TMPDIR}/maxmins.txt | ${GMT} mapproject ${J} ${R}) > ${TMPDIR}/maxmins2.txt
        awk -v mins=${mins} -v umbral=${umbralPress} -f filtrarpresion.awk ${TMPDIR}/maxmins2.txt > ${TMPDIR}/maxmins3.txt
        awk -v n=${nminframesMSL} -f filtrarletras.awk ${TMPDIR}/maxmins3.txt | sort -k1,1 |\
         awk -v N=5 -v nf=4  -v maxfecha=${max} -v minfecha=${minreal} -f suavizarletras.awk> ${TMPDIR}/maxmins4.txt
    else

        cp `dirname $(realpath ${presscfgfile} )`/`basename ${presscfgfile} .cfg`.labels.txt ${TMPDIR}/maxmins4.txt

    fi

    filelines=`wc -l ${TMPDIR}/maxmins4.txt | awk '{print $1}'`

    fecha=${min}
    nframe=0

    # Si el mapa es global hay que pintar las letras con perspectiva
    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        function pintarPresionAyB {
            pintarPresionAyBGlobal
        }
    fi

    printMessage "Generando los frames de máximos/mínimos de MSL desde ${min} hasta ${max} cada ${mins} minutos"


    # Generamos las capas con los máximos y mínimos (si hay alguno que pintar)
    if [ ${filelines} -gt 0 ]
    then
        while [ ${fecha} -le ${max} ]
        do

            grep ^${fecha} ${TMPDIR}/maxmins4.txt | awk '{print $2,$3,$6,$7,$9}' > ${TMPDIR}/contourlabels.txt

            tmpFile="${TMPDIR}/${fecha}-msl-HL.png"

            if [ ${fecha} -ge ${minreal} ]
            then
                printMessage "Generando frame de máximos/mínimos para fecha ${fecha}"
                pintarPresionAyB

                cp ${tmpFile} ${TMPDIR}/mslhl`printf "%03d\n" ${nframe}`.png

                nframe=$((${nframe}+1))
            fi

            fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
        done

        replicarFrames "mslhl"

        printMessage "Uniendo frames de isobaras con frames de máximos y mínimos"
        # Unimos los frames de las isobaras con los de máximos y mínimos
        ${FFMPEG} -f image2 -i ${TMPDIR}/msl%03d.png -f image2 -i ${TMPDIR}/mslhl%03d.png -filter_complex "overlay" ${TMPDIR}/kk%03d.png 2>> ${errorsFile}
        rm -rf ${TMPDIR}/msl*.png
        rename -f 's/kk/msl/' ${TMPDIR}/kk*.png
    fi


fi



# Pintamos las etiquetas
if [ ${pintarEtiquetas} -eq 1 ]
then


    # Usamos la J y R cartesianas
    J="-JX${xlength}c/${ylength}c"
    R=`grdinfo ${dataFileDST} -Ir -C` ####


    fecha=${min}
    nframe=0


    comando="cat"
    # Si el mapa es global hay que pintar las etiquetas con perspectiva
    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        function pintarEtiquetas {
            pintarEtiquetasGlobal
        }
        comando="${GMT} mapproject -JX${xlength}c/${ylength}c ${RAMP}"
    fi

    # Si se ha indicado, que son geográficas se deben pasar las coordenadas a cartesianas
    if [ ! -z ${geoglabels} ] && [  ${geoglabels} -eq 1 ]
    then

        paste -d ";" ${labelsfile} <(awk -F ";" 'BEGIN{OFS=";"}{print $2,$3}' ${labelsfile} |\
         ${GMT} mapproject ${RGEOG} ${JGEOG} | ${comando} | tr "\t" ";" ) |\
         awk -F ";" 'BEGIN{OFS=";"}{print $1,$13,$14,$4,$5,$6,$7,$8,$9,$10,$11,$12}' > ${TMPDIR}/kketiquetas
        labelsfile="${TMPDIR}/kketiquetas"
    fi
    printMessage "Generando los frames de etiquetas desde ${min} hasta ${max} cada ${mins} minutos"


    while [ ${fecha} -le ${max} ]
    do


#        grep ^${fecha} ${labelsfile} | awk -F ";" 'BEGIN{OFS=";"}{print $2,$3,$4,$5,$6,$7,$8}' > ${TMPDIR}/etiquetas.txt
        # El comando cat es para que no devuelva un error 1 si no encuentra la fecha y no se salga
        grep ^${fecha} ${labelsfile} | cat > ${TMPDIR}/etiquetas.txt

        tmpFile="${TMPDIR}/${fecha}-labels.png"

        if [ ${fecha} -ge ${minreal} ]
        then
            printMessage "Generando frame de etiquetas para fecha ${fecha}"
            pintarEtiquetas


            cp ${tmpFile} ${TMPDIR}/labels`printf "%03d\n" ${nframe}`.png

            nframe=$((${nframe}+1))
        fi


        fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
    done

    replicarFrames "labels"

fi





# Pintamos las partículas de viento
if [ ${pintarViento} -eq 1 ]
then

    zmin=9999
    zmax=-9999


    ### PRIMER FRAME

    # w y h son el ancho y el alto cartesiano de la proyección (que no tiene porque coincidir con el de la imagen
    # que estemos pintando)
    read w h < <(${GMT} mapproject ${JGEOG} ${RGEOG} -W)


    np=${nparticulas}

    # Generamos nparticulas aleatorias distribidas por toda la proyección asignandole un tiempo de vida aleatorio
    # entre 1 y max_age. Pasamos las coordenadas a geográficas
    paste <(awk -v var=${w} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
          <(awk -v var=${h} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
           <(shuf -r -n ${np} -i 1-${max_age}) | \
            ${GMT} mapproject ${JGEOG} ${RGEOG} -I >> ${TMPDIR}/particulas.txt
    sed '/^NaN/d' ${TMPDIR}/particulas.txt > ${TMPDIR}/kkparticulas.txt
    mv ${TMPDIR}/kkparticulas.txt ${TMPDIR}/particulas.txt


    fecha=${min}
    fechamax=${max}


    # Si no se ha especificado ninguno el nivel es 0
    [ -z ${windlevel} ] && windlevel=0


    ncFile="${TMPDIR}/${fecha}.nc"
    ncFileU="${TMPDIR}/${fecha}_u.nc"
    ncFileV="${TMPDIR}/${fecha}_v.nc"
    varU="u10"
    varV="v10"

    # Si el nivel es mayor que 0 las variables son u y v en vez de u10 y v10
    if [ ${windlevel} -gt 0 ]
    then
        varU="u"
        varV="v"
    fi

    # Separamos el nivel que queremos
    ${CDO} -sellevel,${windlevel} -selvar,${varU} ${TMPDIR}/${fecha}.nc ${ncFileU} 2>> ${errorsFile}
    ${CDO} -sellevel,${windlevel} -selvar,${varV} ${TMPDIR}/${fecha}.nc ${ncFileV} 2>> ${errorsFile}

    # Recortamos la región deseada
    ${GMT} grdcut ${ncFileU}?${varU} ${Rgeog} -G${ncFileU}
    ${GMT} grdcut ${ncFileV}?${varV} ${Rgeog} -G${ncFileV}

    # Si estamos pinchando rachas de viento cogemos el viento de racha del siguiente paso de tiempo (+3 horas),
    # lo dividimos por el viento medio y multiplicamos eso por la componente U y V
    if [ ! -z ${pintarRachasViento} ] && [ ${pintarRachasViento} -eq 1 ]
    then
        fechasig=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        ${GMT} grdmath ${Rgeog} ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT  = ${TMPDIR}/vientomedio.nc
        ${GMT} grdmath ${Rgeog} ${TMPDIR}/${fechasig}.nc\?fg310 = ${TMPDIR}/vientoracha.nc
        ${GMT} grdmath ${TMPDIR}/vientoracha.nc ${TMPDIR}/vientomedio.nc DIV ${ncFileU} MUL = ${ncFileU}
        ${GMT} grdmath ${TMPDIR}/vientoracha.nc ${TMPDIR}/vientomedio.nc DIV ${ncFileV} MUL = ${ncFileV}
    fi

    [ -z ${bottomwind} ] && bottomwind=0

    # Para cada partícula sacamos su componentes U y V y a través de ellas y de sus coordenadas calculamos el nuevo punto donde se va a situar
    awk '{print $1,$2}' ${TMPDIR}/particulas.txt | ${GMT} grdtrack -G${ncFileU} -G${ncFileV} | \
    awk -v scale=${scale}  -f newlatlon.awk | awk -v umbral=${bottomwind} '$5>=umbral' > ${TMPDIR}/dparticulas.txt

    # Filtramos las partículas para que solo se pinten las que sean superior a determinado umbral
    awk -v umbral=${bottomwind} '$5>=umbral' ${TMPDIR}/dparticulas.txt > ${TMPDIR}/dparticulasfilter.txt


    # Actualizamos el z máximo y el z mínimo
    read zminlocal zmaxlocal < <(awk 'BEGIN{min=9999; max=-9999}$5<min{min=$5}$5>max{max=$5}END{print min" "max}' ${TMPDIR}/dparticulasfilter.txt)
    if (( `echo "${zminlocal} <  ${zmin}" | bc -l` ))
    then
        zmin=${zminlocal}
    fi
    if (( `echo "${zmaxlocal} >  ${zmax}" | bc -l` ))
    then
        zmax=${zmaxlocal}
    fi

    # Si el mapa es global hay que hacer una doble reproyección:
    # 1. De las coordenadas geográficas a las coordenadas cartesianas de la proyección
    # 2. De coordenadas cartesianas de la proyección a las coordenadas cartesianas de la imagen
    comando="cat"
    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        comando="${GMT} mapproject -JX${w}c/${w}c ${RAMP}"
    fi

    # A partir de las coordenadas calculadas generamos un fichero txt con las líneas que hay que pintar
    # Primero hay que pasar las coordenadas geógraficas a cartesianas
    paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulasfilter.txt | ${GMT} mapproject ${RGEOG} ${JGEOG} | ${comando} )\
     <(awk '{print $3,$4}' ${TMPDIR}/dparticulasfilter.txt | ${GMT} mapproject ${RGEOG} ${JGEOG} | ${comando} ) \
     <(awk -fz2color.awk <(${GMT} makecpt -Fr -C${cptViento})  ${TMPDIR}/dparticulasfilter.txt | awk '{printf "rgb(%s,%s,%s)\n",$1,$2,$3}') |\
     awk -v w=${w} -v h=${h} -v xsize=${xsize} -v ysize=${ysize} '{printf "stroke %s line %d,%d %d,%d\n", $5, xsize*$1/w, ysize*(h-$2)/h, xsize*$3/w, ysize*(h-$4)/h}' > ${TMPDIR}/lineas.txt

    # Pintamos las líneas sobre un frame transparente
    ${CONVERT} -size ${xsize}x${ysize} xc:transparent -stroke white -strokewidth 3 -draw "@${TMPDIR}/lineas.txt" png32:${TMPDIR}/000.png


    ### RESTO DE FRAMES

    oldframe="${TMPDIR}/000.png"
    nframe=1
    printMessage "Generando los frames de Partículas de Viento desde ${fecha} hasta ${fechamax}"

    sigmin=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
    while [ ${fecha} -le ${fechamax} ]
    do
        ncFile="${TMPDIR}/${fecha}.nc"
        ncFileU="${TMPDIR}/${fecha}_u.nc"
        ncFileV="${TMPDIR}/${fecha}_v.nc"

        ${CDO} -sellevel,${windlevel} -selvar,${varU} ${TMPDIR}/${fecha}.nc ${ncFileU} 2>> ${errorsFile}
        ${CDO} -sellevel,${windlevel} -selvar,${varV} ${TMPDIR}/${fecha}.nc ${ncFileV} 2>> ${errorsFile}

        # Recortamos la región deseada
        ${GMT} grdcut ${ncFileU}?${varU} ${Rgeog} -G${ncFileU}
        ${GMT} grdcut ${ncFileV}?${varV} ${Rgeog} -G${ncFileV}

        # Si estamos pinchando rachas de viento cogemos el viento de racha del siguiente paso de tiempo (+3 horas),
        # lo dividimos por el viento medio y multiplicamos eso por la componente U y V
        if [ ! -z ${pintarRachasViento} ] && [ ${pintarRachasViento} -eq 1 ]
        then
            fechasig=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
            ${GMT} grdmath ${Rgeog} ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT  = ${TMPDIR}/vientomedio.nc
            ${GMT} grdmath ${Rgeog} ${TMPDIR}/${fechasig}.nc\?fg310 = ${TMPDIR}/vientoracha.nc
            ${GMT} grdmath ${TMPDIR}/vientoracha.nc ${TMPDIR}/vientomedio.nc DIV ${ncFileU} MUL = ${ncFileU}
            ${GMT} grdmath ${TMPDIR}/vientoracha.nc ${TMPDIR}/vientomedio.nc DIV ${ncFileV} MUL = ${ncFileV}
        fi

        # Calculamos los frames de viento que vamos a pintar para fecha
        nframesfecha=${nframes}

        # Si la fecha es la mínima o la siguiente y el mínimo es distino que minreal
        # se pintan menos frames
        if [ ${fecha} -le ${sigmin} ]
        then
            nframesfecha=${nframesinicio}
        fi

        # Si la fecha es el mínimo pintamos los frames iniciales más nframesinicio
        if [ ${fecha} -eq ${min} ]
        then
            nframesfecha=$((${nframesfecha}+${nframesloop}-1))
        fi

        # Si es la ficha final (max) le añadimos el número de frames finales
        if [ ${fecha} -eq ${max} ]
        then
            nframesfecha=$((${nframesfecha}+${nframesfinal}))
        fi

        printMessage "Generando ${nframesfecha} frames para fecha ${fecha}"

        # Se pintan los frames calculados
        for ((i=0; i<${nframesfecha}; i++, nframe++))
        do
            printMessage "Generando frame ${i} de partículas para fecha ${fecha}"

            start_time="$(date -u +%s.%N)"

            # Cogemos aquellas partículas que no se le haya agotado su tiempo de vida
            awk '$3>0' ${TMPDIR}/particulas.txt > ${TMPDIR}/kkparticulas
            n=`wc -l ${TMPDIR}/kkparticulas | awk '{print $1}'`


            # Si se hemos descartado partículas, generamos tantas partículas nuevas como hayamos descartado
            # asignandole un tiempo de vida máximo
            if [ ${n} -lt ${nparticulas} ]
            then
                np=$((${nparticulas}-${n}))

                paste <(awk -v var=${w} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
                      <(awk -v var=${h} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f 50\n",$1/100}') \
                  | ${GMT} mapproject ${RGEOG} ${JGEOG} -I >> ${TMPDIR}/kkparticulas

                sed '/^NaN/d' ${TMPDIR}/kkparticulas > ${TMPDIR}/kkparticulas2
                mv ${TMPDIR}/kkparticulas2 ${TMPDIR}/kkparticulas

                mv ${TMPDIR}/kkparticulas ${TMPDIR}/particulas.txt
            fi


            # Para cada partícula sacamos su componentes U y V y a través de ellas y de sus coordenadas calculamos el nuevo punto donde se va a situar
            awk '{print $1,$2}' ${TMPDIR}/particulas.txt | ${GMT} grdtrack  -G${ncFileU} -G${ncFileV} | \
             awk -v scale=${scale} -f newlatlon.awk  > ${TMPDIR}/dparticulas.txt

            # Filtramos las partículas para que solo se pinten las que sean superior a determinado umbral
            awk -v umbral=${bottomwind} '$5>=umbral' ${TMPDIR}/dparticulas.txt > ${TMPDIR}/dparticulasfilter.txt

            # Actualizamos el z máximo y el z mínimo
            read zminlocal zmaxlocal < <(awk 'BEGIN{min=9999; max=-9999}$5<min{min=$5}$5>max{max=$5}END{print min" "max}' ${TMPDIR}/dparticulasfilter.txt)
            if (( `echo "${zminlocal} <  ${zmin}" | bc -l` ))
            then
                zmin=${zminlocal}
            fi
            if (( `echo "${zmaxlocal} >  ${zmax}" | bc -l` ))
            then
                zmax=${zmaxlocal}
            fi

            # A partir de las coordenadas calculadas generamos un fichero txt con las líneas que hay que pintar
            # Primero hay que pasar las coordenadas geógraficas a cartesianas
            paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulasfilter.txt | ${GMT} mapproject ${RGEOG} ${JGEOG} | ${comando})\
            <(awk '{print $3,$4}' ${TMPDIR}/dparticulasfilter.txt | ${GMT} mapproject ${RGEOG} ${JGEOG} | ${comando}) \
            <(awk -fz2color.awk <(${GMT} makecpt -Fr -C${cptViento}) ${TMPDIR}/dparticulasfilter.txt | awk '{printf "rgb(%s,%s,%s)\n",$1,$2,$3}') |\
            awk -v w=${w} -v h=${h} -v xsize=${xsize} -v ysize=${ysize} '{printf "stroke %s line %d,%d %d,%d\n", $5, xsize*$1/w, ysize*(h-$2)/h, xsize*$3/w, ysize*(h-$4)/h}' > ${TMPDIR}/lineas.txt

            # Le restamos 1 al tiempo de vida de todas las partículas
            paste ${TMPDIR}/particulas.txt ${TMPDIR}/dparticulas.txt | awk '{print $6,$7,$3-1}' > ${TMPDIR}/kkparticulas
            mv ${TMPDIR}/kkparticulas ${TMPDIR}/particulas.txt

            # Le restamos un porcentaje "fade" al canal alpha del frame anterior y sobre ese frame
            # se dibujan las líneas nuevas, quedandose un efecto de estela sobre la partícula
            ${CONVERT} \( ${oldframe} -matte -channel a -evaluate subtract ${fade}% \)\
              \( -size ${xsize}x${ysize} xc:transparent -stroke white -strokewidth 3 -draw "@${TMPDIR}/lineas.txt" \)\
               -composite png32:${TMPDIR}/`printf "%03d" ${nframe}`.png

            oldframe="${TMPDIR}/`printf "%03d" ${nframe}`.png"

            end_time="$(date -u +%s.%N)"
#            echo "Tiempo frame: $(bc <<<"$end_time-$start_time")"



        done

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done

    # Se crea la escala de viento
    if [ ${escalaViento} -eq 1 ]
    then

        ivar=$(( `echo ${indexescala[*]} | tr " " "\n" | sort -nr | head -n 1` + 1 ))
        index=${#indexescala[*]}
        indexescala[${index}]=${ivar}
        cargarVariable "uv"
#        calcularMinMax "${variablefondo}" ${min} ${max} ${stepinterp}
        printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptViento}"
        P=""

        echo ${tipoescala[*]}
        echo ${index} ${tipoescala[${index}]}
        if [ ${tipoescala[${index}]} == "h" ]
        then
            P="-p"
        fi
        ./crearescala.sh ${zmin}/${zmax} ${cptViento} ${TMPDIR}/escala${ivar}.png  ${unidadEscala} "Viento" ${P} #2>> ${errorsFile}
    fi
fi

# Generamos los frames de rótulos
nframerotulo=1
fecha=${minreal}
fechamax=${max}
printMessage "Generando frames de títulos"
while [ ${fecha} -le ${fechamax} ]
do
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframerotulo}`.png

#    TZ=:America/Mexico_City
    # Generamos el texto con la fecha y hora local y en el idioma seleccionado en el fichero de configuración de estilo
    rotuloFecha=`LANG=${idioma} TZ=:${timezone} date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.*\)/\u\1/g"`

    printMessage "Generando frame con el texto para la fecha ${fecha}"

    # Pintamos el título
    ${CONVERT} -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" \
        -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    # Pintamos el subtítulo con la fecha
    ${CONVERT} -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" \
        -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}


    nframerotulo=$((nframerotulo+1))
    if [ ${fecha} -eq ${minreal} ] && [ ${steprotulo} -eq  ${stepviento} ]
    then
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} -${desfasemin} hours" +%Y%m%d%H%M`
    fi

    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +${steprotulo} hours" +%Y%m%d%H%M`
done


# Redimensionamos el tamaño de las escalas si sobrepasan un límite
nescalas=${#indexescala[*]}
escalas=""

for ((i=0; i<${nescalas}; i++))
do
    ivar=${indexescala[${i}]}
    escalas="${escalas} -f image2 -i  ${TMPDIR}/escala${ivar}.png"

    # Si la escala es horizontal
    if [ ${tipoescala[${i}]} == "h" ]
    then
        scalewidth=`${CONVERT} ${TMPDIR}/escala${ivar}.png -ping -format "%w" info:`
        if [ ${scalewidth} -ge 1000 ]
        then
            ${CONVERT} ${TMPDIR}/escala${ivar}.png -resize 1000 ${TMPDIR}/escala${ivar}.png
            scalewidth=1000
        fi

        xscala[${i}]=$((${xscala[${i}]}-${scalewidth}/2))
    else
        scaleheight=`${CONVERT} ${TMPDIR}/escala${ivar}.png -ping -format "%h" info:`
        if [ ${scaleheight} -ge 790 ]
        then
            ${CONVERT} ${TMPDIR}/escala${ivar}.png -resize 85x800\> ${TMPDIR}/escala${ivar}.png
            scaleheight=790
        fi

        yscala[${i}]=$((${yscala[${i}]}-${scaleheight}/2))
    fi
done




# Generamos las anotaciones del final
if [ ${pintarAnotacionesFinal} -eq 1 ]
then

    printMessage "Generando anotaciones al final del vídeo para la variable ${variablefinal}"
    cargarVariable ${variablefinal}

    # Si no existe, generamos el fichero de máximo para la variable final
    if [ ! -f ${TMPDIR}/${max}_${variablefinal}.nc ]
    then
        J=${JGEOG}
        R=${RGEOG}
        function procesarGrid {
                ${funcionesprocesar}
        }
        procesarGrids ${variablefinal} ${max} ${max} ${fechapasada}
        J="-JX${xlength}c/${ylength}c"
        R=`grdinfo ${dataFileDST} -Ir -C` ####
    fi

    # Se calculan las anotaciones en el fichero Tlabels.txt con la función definida en el fichero de configuración del tipo
    calcularAnotaciones
    awk -v unidad=${unidadEscala} '{printf "%s %s %s %s\n",$1,$2,$3,unidad}' ${TMPDIR}/Tlabels.txt > ${TMPDIR}/KKlabels.txt
    mv ${TMPDIR}/KKlabels.txt ${TMPDIR}/Tlabels.txt

    # Se generan los frames con la animación de las anotaciones
    pintarAnotaciones ${TMPDIR}/Tlabels.txt
fi


### GENERACIÓN DEL TEXTO DEL FILTRO Y DE LAS OPCIONES


# Primer rótulo
opciones=" -f image2 -i ${TMPDIR}/rotulo-001.png"
finicial=${nframesrotulo}
ffinal=$(( ${nframesinicio}+${nframesloop} -1 ))


# Fondo del mar
# Obtenemos el número de frames que tienen el vídeo del fondo del mar. El vídeo de mar se replica de forma infinita y se
# cogen los frames que vayamos a necesitar
nframesmar=`${FFMPEG} -i ${fondomar} -vcodec copy -f rawvideo -y /dev/null 2>&1 | tr ^M '\n' | awk '/^frame=/ {print $2}'|tail -n 1`
filtro="[$((${nframerotulo}+${nlogos}+${pintarViento}+${nescalas}+1))]loop=-1:${nframesmar}:0[mar];[mar]trim=start_frame=0:end_frame=$((${nframefinal}+${nframesfinal}))[mar];[mar][0]overlay[out];"

# Animación del fundido entre el mapa base y el mapa con variables
# Si fadein es 0 no hay animación
fadefilter="fade=in:$((${nframesloop}-${fadein})):${fadein}"
[ ${fadein} -eq 0 ] && fadefilter="copy"

# Frames de partículas de viento
if [ ${pintarViento} -eq 1 ]
then
    filtro="${filtro}[1]${fadefilter}[viento];"
    framesViento="-f image2 -i ${TMPDIR}/%03d.png"
fi

# Si es un mapa global se multiplica la sombra sobre el fondo base con la animación del mar
# Se aplica el filtro raro para que no aparezca pintado de color magenta
if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then

    filtro="${filtro}[out]setsar=sar=1,format=rgba[out];[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarPresion}+${pintarViento}+${nescalas}+2))]setsar=sar=1,format=rgba[sombra];[out][sombra]blend=all_mode=multiply:all_opacity=1,format=yuva422p10le[out];"
    frameSombra=" -f image2 -i ${filesombra}"
fi


# Frames de variables
framesUV=""
if [ ${pintarIntensidad} -eq 1 ]
then
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarViento}+${nescalas}+2))]${fadefilter}[uv];[out][uv]overlay[out];"
    framesUV="-f image2 -i ${TMPDIR}/${variablefondo}%03d.png"
fi

# El viento se pinta encima del resto de variables
if [ ${pintarViento} -eq 1 ]
then
    filtro="${filtro}[out][viento]overlay[out];"
fi

# La presión se pinta encima de las particulas de viento y del resto de variables
if [ ${pintarPresion} -eq 1 ]
then
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarViento}+${nescalas}+2))]${fadefilter}[press];[out][press]overlay[out];"
    framesPress="-f image2 -i ${TMPDIR}/msl%03d.png"
fi

# Etiquetas del usuario
if [ ${pintarEtiquetas} -eq 1 ]
then
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarPresion}+${pintarViento}+${nescalas}+${global}+2))]${fadefilter}[labels];[out][labels]overlay[out];"
    frameslabels="-f image2 -i ${TMPDIR}/labels%03d.png"
fi


# Anotaciones del final
if [ ${pintarAnotacionesFinal} -eq 1 ]
then

    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarPresion}+${pintarViento}+${nescalas}+${global}+2))]setpts=1*PTS+${nframefinal}/(25*TB)[anotaciones];[out][anotaciones]overlay[out];"
    framesanotaciones="-f image2 -i ${TMPDIR}/anot%03d.png"
fi

# Colocamos las escalas
for ((i=0; i<${nescalas}; i++))
do
    filtro="${filtro}[$((${pintarViento}+${i}+1))]loop=20:1:0[escala${i}];[escala${i}]fade=in:0:10[escala${i}];[out][escala${i}]overlay=x=${xscala[${i}]}:y=${yscala[${i}]}[out];"
done

# Colocamos el cartel del título
filtro="${filtro}[out][$((${pintarViento}+${nescalas}+1))]overlay=x=${xcartel}:y=${ycartel}[out];[out][$((${pintarViento}+${nescalas}+2))]overlay=enable=between(n\,${finicial}\,${ffinal})"

# Opciones de filtro para solapar los rotulos
nframesrotuloi=$(( ${steprotulo}*60/${mins} ))
nstep=0
nstepinicio=1
j=0
nfinicio=${nframesinicio}
for((i=2; i<${nframerotulo}; i++))
do
    opciones="${opciones} -f image2 -i ${TMPDIR}/rotulo-`printf "%03d" ${i}`.png"

    finicial=$(( ${nstepinicio}*${nframesinicio}+${nstep}*${nframes}+${nframesloop} + ${j}*${slowmotion}*${nframesrotuloi}  ))
    ffinal=$(( ${nstepinicio}*${nframesinicio}+${nstep}*${nframes}+${nframesloop} + (${j}+1)*${slowmotion}*${nframesrotuloi} -1 ))

    if [ $(( (${i} + ${desfasemin} -1) % (${stepviento}/${steprotulo}) )) -eq 0 ]
    then


        if [ ${nstepinicio} -lt 2 ]
        then
            nstepinicio=$((${nstepinicio}+1))
        else
            nstep=$((${nstep}+1))
        fi
        ffinal=$(( ${nstep}*${nframes}+${nframesloop}+${nframesinicio}*${nstepinicio} -1 ))
        j=0
    else
        j=$((${j}+1))
    fi

    if [ ${i} -eq $((${nframerotulo}-1)) ]
    then
        ffinal=$((${ffinal}+${nframesfinal}))
    fi

    filtro="${filtro}[out];[out][$((${i}+${nescalas}+${pintarViento}+1))]overlay=enable=between(n\,${finicial}\,${ffinal})"

done





# Ponemos los logos
logos=""
if [ ${nlogos} -gt 0 ]
then
    logos="-f image2 -i ${logo[0]} "
    filtro="${filtro}[out];[out][$((${nframerotulo}+1+${pintarViento}+${nescalas}))]overlay=${xlogo[0]}:${ylogo[0]}"
fi

for((nlogo=1; nlogo<${nlogos}; nlogo++))
do
    logos="${logos} -f image2 -i ${logo[${nlogo}]} "
    filtro="${filtro};[out][$((${nframerotulo}+${nlogo}+1+${pintarViento}+${nescalas}))]overlay=${xlogo[${nlogo}]}:${ylogo[${nlogo}]}"
done


#echo $filtro
printMessage "Generando vídeo final....."


# Generamos el vídeo del final
${FFMPEG} -y -f image2 -i ${fondoPNG} ${framesViento} ${escalas} -f image2 -i ${framescartel} ${opciones} ${logos} -i ${fondomar} \
 ${framesUV} ${framesPress} ${frameSombra} ${framesanotaciones} ${frameslabels} -filter_complex ${filtro}  ${outputFile} 2>> ${errorsFile}

printMessage "¡Se ha generado el vídeo `basename ${outputFile}` con exito!"

rm -rf ${dir}
