#!/bin/bash
###############################################################################
# Script que permite configurar la aparición de las letras de los centros de alta
# y baja presión, y determinar su trayectoria. Si se selecciona otra variable se
# calculará la trayectoria de sus puntos máximos y mínimos.
# El fichero de configuración que genera podrá ser leido por el script animación.sh
# y el video resultante tendrá las letras calculadas aquí.
#
# Se generan 6 ficheros:
# - output.txt: Resumen de las letras que aparecerán durante la animación.
# - output.png: Imagen con mapa base de fondo donde se muestra la trayectoria de las letras durante la animación.
# - output-0.png: Primer frame que se generará en la animación.
# - output-1.png: Último frame que se generará en la animación.
# - output.labels.txt: Fichero txt con las coordenadas de las letras, valor de presión y valor de transparencia
# a lo largo de la animación
# - output.cfg: Fichero de configuración, que puede ser leido por el script animacion.sh
#
#
# Uso:
# presslabels.sh fechainicio fechafinal [-f archivo] [-d fechapasada] [-g geogcfgfile] [-m minutos] [-v variable]
#                [-r] [-o] [-h] [--press_minframes nframes] [--press_threshold threshold] [--press_resolution res]
#                [--pressexclude idsexclude]"
#
#
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      24/10/2018
###############################################################################


# Nombre del script.
scriptName=`basename $0`

# Función que define la ayuda sobre este script.
function usage() {

      echo
      echo "Permite configurar la aparición de las letras de los centros de alta y baja presión, y determinar su trayectoria."
      echo
      echo "Uso:"
      echo "${scriptName} fechainicio fechafinal [-f archivo] [-d fechapasada] [-g geogcfgfile] [-m minutos] [-v variable]"
      echo "                    [-r] [-o] [-h] [--press_minframes nframes] [--press_threshold threshold] [--press_resolution res]"
      echo "                    [--press_smooth smooth] [--pressexclude idsexclude] [--clean]"
      echo
      echo " fechainicio :               Fecha en la que comenzará la animación del vídeo. En formato yyyyMMddhh (UTC)."
      echo
      echo " fechafinal :                Fecha en la que finalizará la animación del vídeo. En formato yyyyMMddhh (UTC)."
      echo
      echo " -f archivo:                 Prefijo de los nombres de los ficheros de salida. Por defecto out."
      echo
      echo " -d fechapasada:             Fecha de la pasada de la que se van a coger los grids de entrada. Por defecto se coge la"
      echo "                             última pasada disponible que sea menor que la fecha de inicio. En formato yyyyMMddhh (UTC)."
      echo
      echo " -g geogcfgfile:             Fichero de configuración geográfica. Se pueden generar con el script MapaBase3.sh."
      echo "                             Por defecto spain3.cfg."
      echo
      echo " -m minutos:                 Minutos en los que se interpolará un frame en la animación. Debe ser un divisor de 60. Un valor menor hace "
      echo "                             que la animación haga una transición más suave pero la generación del vídeo será más lenta. Por "
      echo "                             defecto es 60."
      echo
      echo " -v variable:                Variable de la que queremos sacar su máximos y mínimos. Por defecto es presión."
      echo
      echo " -r:                         Se repite la ejecución anterior. No tendrá que volver a procersar los grids, tomando como base el "
      echo "                             el último directorio temporal. Con esta opción activada solo se pueden modificar los parámetros "
      echo "                             --press_minframes y --press_smooth."
      echo
      echo "--press_minframes nframes:   Número mínimo de frames consecutivos en los que debe aparecer una letra. Por defecto es la "
      echo "                             la cuarta parte del número total de frames."
      echo
      echo "--press_threshold threshold: Distancia mínima entre letras. Entre dos frames consecutivos dos letras serán consideradas "
      echo "                             como la misma si su distancia es inferior. En un mismo frame será descartada una letra que esté a menos "
      echo "                             de esta distancia. Por defecto se calcula autómaticamente en función del zoom de la proyección y los mínutos "
      echo "                             de la interpolación."
      echo
      echo "--press_resolution res:      Resolución a la que se resamplea la presión. Con el fin de obtener isobaras más suavizadas se resamplea "
      echo "                             el grid de presión a una resolución menor. Por defecto es 0.5."
      echo
      echo "--press_smooth smooth:       Factor de suavizado. Para obtener isobaras más suavizadas se aplica una mascacara de convolución de  "
      echo "                             suavizado. Por defecto es 19."
      echo
      echo "--pressexclude idsexclude:   Si no queremos determinadas letras en la animación podemos excluirlas con esta opción. 'idexclude'"
      echo "                             debe tener el formato 'id0/id1/.../idn' donde idx es el id de una de las letras que queremos excluir."
      echo
      echo "--clean:                     Borra todos los directorios temporales excepto los que están siendo utilizados por algún proceso. No se"
      echo "                             puede utilizar junto a la opción -r."
      echo
      echo " -o:                         Sobreescribe todos los ficheros sin preguntar si existen."
      echo
      echo " -h:                         Muestra esta ayuda."
      echo
      echo "El fichero default.cfg define las variables de configuración de este comando."

}


# Función que borra los directorios temporales
function borrarDirectoriosTemporales() {
    # Busca los directorios temporales que estén siendo bloqueados por otros proceso
    excludedirs=`ls ${TMPBASEDIR}/$(basename $(type $0 | awk '{print $3}')).*/lock |\
     sed 's/\'${TMPBASEDIR}'\/\(.*\)\/lock/\1/' | awk '{printf "! -name %s ",$0}'`
    # Borra todos los directorios temporales excepto los que esten siendo utilizados
    find ${TMPBASEDIR}/ -name "$(basename $(type $0 | awk '{print $3}')).*" ${excludedirs} -type d -exec rm -rf {} + 2> /dev/null
}


# Parsea los argumentos pasados al comando a través de la línea de comandos
function parseOptions() {
    OVERWRITE=0

    if [ $# -eq 0 ]
    then
       echo "Error: el número de argumentos mínimo es 2" >&2; usage; exit 1
    fi
    execute=0

    if [ $1 != "-h" ] && [ $1 != "--clean" ]
    then
        execute=1
        if [ $# -lt 2 ]
        then
           echo "Error: el número de argumentos mínimo es 3" >&2; usage; exit 1
        fi

        # Expresiones regulares
        refloat="^[+-]?[0-9]+([.][0-9]+)?$"
        reint="^[+-]?[0-9]+$"
        repos="^[0-9]+$"
        refecha="^[0-9]{10}$"
        rebin="^[0-1]{1}$"



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
    options=$(getopt -o hd:g:m:of:rv: --long press_minframes: --long pressexclude: --long press_threshold: \
     --long press_resolution: --long press_smooth: --long clean -- "$@")

    if [ $? -ne 0 ]
    then
        usage; exit 1
    fi


    # set -- opciones: cambia los parametros de entrada del script por los especificados en opciones y en ese orden. la opción "--"
    # hace que tenga en cuenta tambien los argumentos que empiezan por "-" (sino los omite).
    eval set -- "${options}"

    while true; do
        case "$1" in
        -v)
            shift
            variablePARAM=$1;
            ;;
        -r)
            ultimoTMP=1;
            ;;
        -f)
            shift
            outputFile=$1
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

        -m)
            shift
            minsParam=$1
            ! [[ ${minsParam} =~ ${repos} ]] || [ $(( 60 % ${minsParam} )) -ne 0 ] && \
                { echo "Error: El valor mins debe entero positivo y divisor de 60." >&2; usage; exit 1; }
            ;;

        --press_minframes)
            shift
            nminframesMSLParam=$1
            ! [[ ${nminframesMSLParam} =~ ${repos} ]] &&  \
                { echo "Error: El valor --press_minframes debe entero positivo." >&2; usage; exit 1; }
            ;;

        --press_threshold)
            shift
            umbralPressParam=$1
            ! [[ ${umbralPressParam} =~ ${refloat} ]] && (( `echo "${umbralPressParam} <  0 " | bc -l` )) && \
                { echo "Error: El valor --press_threshold debe real mayor o igual que 0." >&2; usage; exit 1; }
            ;;

        --press_resolution)
            shift
            presresPARAM=$1
            ! [[ ${presresPARAM} =~ ${refloat} ]] && (( `echo "${presresPARAM} <=  0 " | bc -l` )) && \
                { echo "Error: El valor --press_resolution debe real mayor que 0." >&2; usage; exit 1; }
            ;;

        --press_smooth)
            shift
            pressmoothPARAM=$1
            ! [[ ${pressmooth} =~ ${repos} ]] || [ ${pressmooth} -le 0 ] || [ $(( ${pressmooth} % 2 )) -eq 0 ] && \
                { echo "Error: El valor --pressmooth tiene que ser positivo impar mayor que 0" >&2; usage; exit 1; }
            ;;

        --pressexclude)
            shift
            idpressexclude=(`echo $1 | tr "/" " "`)
            ;;

        --clean)
            CLEAN=1
            [ ${execute} -eq 0 ] && { borrarDirectoriosTemporales; exit 0; };
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


# Directorio donde se llama al script
dirprev=${PWD}

cd `dirname $0`

# Cargamos las variables por defecto, las funciones y la configuración de las variables de los grids
source defaults.cfg
source funciones.sh
source funciones-variables.sh
source variables.sh


#### Variables por defecto
mins=60


variable="press"

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



# Prefijo por defecto de los fichero de salida
outputFile="out"
# Indica si se va a reutilizar el último directorio temporal generado
ultimoTMP=0
# Indica si se borran o no los directorios temporales
CLEAN=0

# Comprobación de que existe el software.
command -v ${GMT} > /dev/null 2>&1 || { echo "error: ${GMT} no está instalado." >&2; usage; exit 1; }
command -v ${CONVERT}  > /dev/null 2>&1 || { echo "error: ${CONVERT} no está instalado." >&2; usage; exit 1; }
command -v ${COMPOSITE}  > /dev/null 2>&1 || { echo "error: ${COMPOSITE} no está instalado." >&2; usage; exit 1; }


parseOptions "$@"

# Si la ruta no es absoluta debe generarse el fichero de salida donde se ejecuto el script
if ! [[ ${outputFile} == /* ]]
then
    outputFile=`realpath ${dirprev}/${outputFile}`
fi

# Chequeamos que existen los directorios
checkDIRS

# Si no se ha pasado archivo de conf geográfico o de estilo por parámetro se cogen estos por defecto
[ -z ${geogfile} ] && geogfile="${GEOGCFGDIR}/europa3.cfg"

# Comprobamos que existen los ficheros de configuración
[ ! -f "${geogfile}" ] && \
    { echo "Error: No existe el fichero de configuración geográfica ${geogfile}" >&2; usage; exit 1; }


source ${geogfile}


# Chequeamos los archivos del fichero de configuración geográfica
#[ ! -z ${GLOBEFILE} ] && [ ! -f ${GLOBEFILE} ] && \
#    { echo "Error: No se ha encontrado el fichero ${GLOBEFILE}" >&2; usage; exit 1; }
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
awk -v scale=${scale} -f awk/newlatlon.awk | awk '{print $1,$2; print $3,$4}' | ${GMT} mapproject ${J} ${R} |\
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




# Modificamos las variables según los parámetros pasados
[ ! -z ${minsParam} ] && mins=${minsParam}
[ ! -z ${fechapasadaParam} ] && fechapasada=${fechapasadaParam}
[ ! -z ${nminframesMSLParam} ] && nminframesMSL=${nminframesMSLParam}
[ ! -z ${variablePARAM} ] && variable=${variablePARAM}
[ ! -z ${presresPARAM} ] && presres=${presresPARAM}


# Número mínimo de frames seguidos que debe aparecer una letra de Baja o Alta presión
# Está configurado como la mitad de los frames de la animación
[ -z ${nminframesMSL} ] && \
    nminframesMSL=$(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(${mins}*60*4) ))


# Chequeamos que la lista de IDs a excluir tienen el formato correcto
repos="^[0-9]+$"
for ((i=0; i<${#idpressexclude[*]}; i++))
do
     ! [[ ${idpressexclude[${i}]}  =~ ${repos} ]] &&
        { echo "Error: El parámetro ${idpressexclude[${i}]} no tiene un formato correcto" >&2; usage; exit 1; }
done


# Determina como de cerca tiene que estar un punto de baja o alta presión, entre frames, para considerarse que es el mismo
# En cms
umbralPress=`awk -v w=${w} -v h=${h} 'BEGIN{printf "%.2f %.2f 0 1\n",w/2,h/2}' | ${GMT} mapproject  ${J} ${R} -I |\
  awk -v scale=100 -f awk/newlatlon.awk | awk '{print $1,$2; print $3,$4}' | ${GMT} mapproject ${J} ${R} |\
   awk -v mins=${mins} 'NR==1{x1=$1; y1=$2}NR==2{print mins/30*1000*($2-y1)}'`

# Si se ha pasado uno por parámetro se establece ese umbral
[ ! -z ${umbralPressParam} ] && umbralPress=${umbralPressParam}
# Establecemos la distancia mínima entre letras como el umbral
dminletras=${umbralPress}







# Si se decide repetir la última ejecución obtenemos el último directorio temporal utilizado
if [ ${ultimoTMP} -eq 1 ]
then
    [ ${CLEAN} -eq 1 ] && \
        { echo "Error: La opción --clean no se puede usar junto a la opción -r" >&2; usage; exit 1; }
    dir=`ls -1dtr ${TMPBASEDIR}/$(basename $(type $0 | awk '{print $3}')).* | tail -n 1`
fi

if [ ! -z ${dir} ]
then
    # Si se repite la última ejecución comprobamos que la última configuración coincide con los parámertros pasados
    TMPDIR=${dir}
    fileconfig="${TMPDIR}/config"
    [ ! -f ${fileconfig} ] && \
        { echo "Error: No se ha encontrado fichero config en el último directorio temporal" >&2; usage; exit 1; }
    [ ${variable} != `sed -n '1p' ${fileconfig}` ] && \
        { echo "Error: No se uso la variable ${variable} en la ejecución anterior" >&2; usage; exit 1; }
    [ ${fechapasada} -ne `sed -n '2p' ${fileconfig} ` ] && \
        { echo "Error: La fecha de pasada ${fechapasada} es distinta que la de la ejecución anterior" >&2; usage; exit 1; }
    [ ${min} -lt `sed -n '3p' ${fileconfig} | awk '{print $1}'` ] && \
        { echo "Error: El mínimo definido ${min} es menor que el de la ejecución anterior" >&2; usage; exit 1; }
    [ ${max} -gt `sed -n '3p' ${fileconfig} | awk '{print $2}'` ] && \
        { echo "Error: El mínimo definido ${max} es mayor que el de la ejecución anterior" >&2; usage; exit 1; }
    [ ${mins} -ne `sed -n '4p' ${fileconfig}` ] && \
        { echo "Error: El valor mins ${mins} es distinto al de la ejecución anterior" >&2; usage; exit 1; }
    [ ${geogfile} != `sed -n '5p' ${fileconfig}` ] && \
        { echo "Error: El fichero de configuración geográfica ${geogfile} es distinto al de la ejecución anterior" >&2; usage; exit 1; }
    [ ${presres} != `sed -n '6p' ${fileconfig}` ] && \
        { echo "Error: El valor presres ${presres} es distinto al de la ejecución anterior" >&2; usage; exit 1; }
    [ ${umbralPress} != `sed -n '7p' ${fileconfig}` ] && \
        { echo "Error: El valor umbralPress ${umbralPress} es distinto al de la ejecución anterior" >&2; usage; exit 1; }

else
    # Diretorio temporal
    TMPDIR=${TMPBASEDIR}/`basename $(type $0 | awk '{print $3}').$$`
    mkdir -p ${TMPDIR}
fi

# Si no lo está, creamos un archivo lock para el directorio no pueda ser borrado ni utilizado por otro proceso
[ -f ${TMPDIR}/lock ] && \
    { echo "Error: El directorio temporal ${TMPDIR} está siendo usado por otro proceso" >&2; usage; exit 1; } || \
touch ${TMPDIR}/lock

# Se borran los directorios temporales que no estén bloqueados
[ ${CLEAN} -eq 1 ] && borrarDirectoriosTemporales

# Definimos que el script pare si se captura alguna señal de terminación o se produce algún error
trap "rm -f ${TMPDIR}/lock; echo 'error: señal interceptada. Saliendo' >&2;exit 1" 1 2 3 15
trap "echo 'error: ha fallado la ejecución. Saliendo' >&2;exit 1" ERR


# Fichero de errores
errorsFile="${TMPDIR}/errors.txt"
touch ${errorsFile}


# Guardamos la J y la R geográficas ya que la J y la R iran cambiando entre geográficas y cartesianas
JGEOG=${J}
RGEOG=${R}

# Chequeamos que existen los grids necesarios para obtener las variables creando un enlace simbólico
checkGrids ${min} ${max} ${fechapasada}


pintarPresion=1
# Pintamos las isobaras
if [ ${pintarPresion} -eq 1 ]
then


    # Usamos la J y R geográficas
    J=${JGEOG}
    R=${RGEOG}

    cargarVariable ${variable}


    # Si no se repite la ejecución anterior se procesan los grids
    if [ ${ultimoTMP} -eq 0 ]
    then
        printMessage "Procesando los grids para la variable '${variable}' desde ${min} hasta ${max}"

        var=${variable}
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
                 var=${variablesprocesar[${nvar}]}
                 nvar=$((${nvar}+1))
            fi

            function procesarGrid {
                ${funcion}
            }
            procesarGrids ${var} ${min} ${maxvariable} ${fechapasada}
        done

    fi

    # Usamos la J y R cartesianas
    J="-JX${xlength}c/${ylength}c"
    R=`${GMT} grdinfo  ${TMPDIR}/${min}_${variable}.nc -Ir -C` ####

    #Redifinimos la función pintarVariable
    function pintarVariable {
        pintarPresion $1
    }

    # Si no se repite la ejecución se interpola los grids
    if [ ${ultimoTMP} -eq 0 ]
    then
        # Si la variable no es presión se estableze hmsl como el mínimo y lmsl como el máximo para que
        # salgan todos los máximos y mínimos
        if [ ${variable} != "press" ]
        then
            calcularMinMax "${variable}" ${min} ${max} ${stepinterp}
            hmsl=${zmin}
            lmsl=${zmax}
        fi
        # Interpolamos los grids
        interpolarFrames ${variable} ${min} ${max} ${mins} 3
    fi

    # Si se repite la ejecución se borra el antiguo archivo de máximos y mínimos
    [ ${ultimoTMP} -eq 1 ] && [ -f ${TMPDIR}/maxmins.txt ] &&
        rm ${TMPDIR}/maxmins.txt

    # Calculamos los máximos y mínimos para todos los grids
    fecha=${min}
    while [ ${fecha} -le ${max} ]
    do
        printMessage "Calculando maximos y mínimos para fecha ${fecha}"
        tfile=${TMPDIR}/${fecha}_${variable}.nc
        generarMaxMinPresion ${tfile}

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
    done

    calcularMaxMinPress=0
    # Generamos el frame del primer grid
    generarFrames ${variable} ${min} ${min} ${mins} "none" 1
    mv ${TMPDIR}/${min}-${variable}-fhd.png ${outputFile}-0.png
    # Generamos el frame del último grid
    generarFrames ${variable} ${max} ${max} ${mins} "none" 1
    mv ${TMPDIR}/${max}-${variable}-fhd.png ${outputFile}-1.png


    printMessage "Calculando máximos/mínimos de ${variable} desde ${min} hasta ${max}"

    # Filtramos los máximos A y lo mínimos B quitando aquellos que aparezcan menos frames de nminframes. Esto evita que aparezcan A y B que aparecen y desaparecen rapidamente
    # 1. Pasamos las coordenadas geográficas a cartesianas
    # 2. Le ponemos un ID a las letras identificando cuales son las mismas entre distintas fechas. Si la distancia entre distintas fechas
    # de dos letras es menor que umbralPress consideramos que es la misma letra
    # 3. Descartamos aquellas que no aparezcan en mas de nminframes consecutivas. Suavizamos también el movimiento de las letras y hacemos
    # que aparezcan y desaparezcan también de forma suave
    paste <(awk '{print $1"\t"$2"\t"$3}' ${TMPDIR}/maxmins.txt) <(awk '{print $2,$3,$4,$5}' ${TMPDIR}/maxmins.txt | ${GMT} mapproject ${J} ${R}) > ${TMPDIR}/maxmins2.txt
    awk -v mins=${mins} -v umbral=${umbralPress} -f awk/filtrarpresion.awk ${TMPDIR}/maxmins2.txt > ${TMPDIR}/maxmins3.txt
    awk -v n=${nminframesMSL} -f awk/filtrarletras.awk ${TMPDIR}/maxmins3.txt | sort -k1,1 |\
     awk -v N=5 -v nf=4  -v maxfecha=${max} -v minfecha=${minreal} -f awk/suavizarletras.awk> ${TMPDIR}/maxmins4.txt

    # Filtramos las letras para que no aparezcan la de los ids excluidos
    if [ ${#idpressexclude[*]} -gt 0 ]
    then
        echo -n > ${TMPDIR}/maxminsexcluded.txt
        for ((i=0; i<${#idpressexclude[*]}; i++))
        do
            awk -v id=${idpressexclude[${i}]} '$8!=id' ${TMPDIR}/maxmins4.txt > ${TMPDIR}/maxminsexcluded.txt
            mv ${TMPDIR}/maxminsexcluded.txt ${TMPDIR}/maxmins4.txt
        done

    fi

    filelines=`wc -l ${TMPDIR}/maxmins4.txt | awk '{print $1}'`


    ${GMT} psbasemap ${R} ${J} -B+n -Xc -Yc --PS_MEDIA=${xlength}cx${ylength}c --MAP_FRAME_PEN="0p,black" -P -K > ${outputFile}.ps

    echo -n > ${outputFile}.txt
    # Para cada letra representada por su ID escribimos su resumen en el fichero output.txt
    # y pintamos la trayectoria en el fichero output.png
    while read line
    do
        code=`echo ${line} | awk '{print $1}'`
        letra=`echo ${line} | awk '{print $2}'`
        color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`

        inicio=`awk -v code=${code} '$8==code' ${TMPDIR}/maxmins4.txt  | head -n 1`
        fin=`awk -v code=${code} '$8==code' ${TMPDIR}/maxmins4.txt  | tail -n 1`
        count=`awk -v code=${code} '$8==code' ${TMPDIR}/maxmins4.txt  | wc -l`

        echo ${inicio} | awk '{printf "%s\t%s\t%s\t",$8,$1,$6}'  >> ${outputFile}.txt
        echo ${fin} | awk '{printf "%s\t%s\t%s\t",$1,$6,$7}' >> ${outputFile}.txt
        echo ${count} >> ${outputFile}.txt

        # Pintamos la trayectoria que sigue la letra
        awk -v code=${code} '$8==code{print $2,$3}' ${TMPDIR}/maxmins4.txt  | ${GMT} psxy ${R} ${J} -Xc -Yc -W2p,${color} -K -O >> ${outputFile}.ps
        # Pintamos el ID en el final de la trayectoria de la letra
        awk -v code=${code} '$8==code{print $2,$3,$8}' ${TMPDIR}/maxmins4.txt  | tail -n 1 | ${GMT} pstext  ${R} ${J} -Xc -Yc -F+f16p,Helvetica-Bold,black  -K -O >> ${outputFile}.ps

    done < <(awk '{print $8,$7}' ${TMPDIR}/maxmins4.txt | sort -n | uniq)

    # Escribimos el número de frames totales
    echo "Frames totales: $(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(${mins}*60)+1 ))" >> ${outputFile}.txt

    cat ${outputFile}.txt

    # Si no existe escribimos un fichero config en el directorio temporal para futuras ejecuciones
    if [ ! -f ${TMPDIR}/config ]
    then
        echo ${variable} > ${TMPDIR}/config
        echo ${fechapasada} >> ${TMPDIR}/config
        echo ${min} ${max} >> ${TMPDIR}/config
        echo ${mins} >> ${TMPDIR}/config
        echo ${geogfile} >> ${TMPDIR}/config
        echo ${presres} >> ${TMPDIR}/config
        echo ${umbralPress} >> ${TMPDIR}/config
    fi

    # Creamos el fichero output.cfg
    cp ${TMPDIR}/config ${outputFile}.cfg
    echo ${pressmooth} >>${outputFile}.cfg
    echo ${nminframesMSL} >>${outputFile}.cfg

    # Creamos el fichero output.labels.cfg
    cp ${TMPDIR}/maxmins4.txt ${outputFile}.labels.txt

    ${GMT} psbasemap ${R} ${J} -B+n -O >> ${outputFile}.ps

    ${GMT} psconvert ${outputFile}.ps -P -TG -Qg1 -Qt4

    ${COMPOSITE} \( ${outputFile}.png -resize ${xsize}x${ysize}! \) ${fondoPNGmar} ${outputFile}.png
fi

# Desbloqueamos el directorio
rm -f ${TMPDIR}/lock