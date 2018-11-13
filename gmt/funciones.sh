#!/bin/bash

###############################################################################
# Definición de funciones que se usan en los scripts de animación.
#
#
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      04/10/2018
###############################################################################


# Función que amplia la R de GMT para que al cortar la región en un grid no se corte cuando se pinta un frame.
# Si la proyección es cilindrica no hay problema. Si es orthográfica o estereográfica habrá que ampliar.
# Parámetros:
#   $1: R de la proyección
#   $2: J de la proyección
# Rgeog lleva la R ampliada
function RGeog {

    local R=$1
    local J=$2

    proy=`echo ${J} | sed -n 's/\-J\(.\).*/\1/p'`
    if [ ${R} != "-Rd" ] && ( [ ${proy} == "G" ] || [ ${proy} == "S" ] )
    then



        #Ampliamos R para que al pintar el mapa de la variable no se vea recortado por la proyección ortográfica
        w=`${GMT} mapproject ${J} ${R} -W | awk '{printf "%f",$1}'`
        h=`${GMT} mapproject ${J} ${R} -W | awk '{printf "%f",$2}'`
        lonmin1=`echo 0 ${h} | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)-0.5}'`
        lonmin2=`echo 0 0 | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)-0.5}'`

        if (( `echo "${lonmin1} < ${lonmin2}" | bc -l` ))
        then
            lonmin=${lonmin1}
        else
            lonmin=${lonmin2}
        fi



        lonmax1=`echo ${w} ${h} | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)+0.5}'`
        lonmax2=`echo ${w} 0 | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)+0.5}'`

        if (( `echo "${lonmax1} > ${lonmax2}" | bc -l` ))
        then
            lonmax=${lonmax1}
        else
            lonmax=${lonmax2}
        fi


        lonmed=`awk -v w=${w} 'BEGIN{printf "%.2f",w/2}'`

        latmin1=`echo 0 0 | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`
        latmin2=`echo ${lonmed} 0 | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`
        latmin3=`echo ${w} 0 | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`

        if (( `echo "${latmin1} < ${latmin2}" | bc -l` )) && (( `echo "${latmin1} < ${latmin3}" | bc -l` ))
        then
            latmin=${latmin1}
        elif (( `echo "${latmin2} < ${latmin3}" | bc -l` ))
        then
            latmin=${latmin2}
        else
            latmin=${latmin3}
        fi

        if (( `echo "${latmin1} < -90" | bc -l` ))
        then
            latmin=-90
        fi


        latmax1=`echo 0 ${h} | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`
        latmax2=`echo ${lonmed} ${h} | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`
        latmax3=`echo ${w} ${h} | ${GMT} mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`

        if (( `echo "${latmax1} > ${latmax2}" | bc -l` )) && (( `echo "${latmax1} < ${latmax3}" | bc -l` ))
        then
            latmax=${latmax1}
        elif (( `echo "${latmax2} > ${latmax3}" | bc -l` ))
        then
            latmax=${latmax2}
        else
            latmax=${latmax3}
        fi

        Rgeog="-R${lonmin}/${lonmax}/${latmin}/${latmax}"

    elif [ ${R} == "-Rd" ]
    then
        Rgeog=${R}
    else
        Rgeog=`echo ${R} | sed 's/^-R//' | awk -F "/" '{printf "-R%.2f/%.2f/%.2f/%.2f",$1-0.1,$2+0.1,$3-0.1,$4+0.1}'`

    fi
}


# Función que chequea si existe un directorio y sino pregunta y lo crea
# Parámetros:
#   $1: R de la proyección
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

# Función que chequea los directorios y los crea si no existen
function checkDIRS () {

    checkdir ${PREFIX}
    checkdir ${DIRROTULOS}
    checkdir ${DIRESTILOS}
    checkdir ${DIRLOGOS}
    checkdir ${DIRFONDOS}
    checkdir ${DIRFRONTERAS}
    checkdir ${GEOGCFGDIR}
    checkdir ${CFGDIR}
    checkdir ${CPTDIR}
    checkdir ${GLOBEDIR}
    checkdir ${DIRNETCDF}

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
        ${OGR2OGR} -where "ISO2='${cod}'" -f "GMT" ${file} ${DIRFRONTERAS}/gadm28_adm0.shp
    else
        i=$((${#array[@]}-1))
        ${OGR2OGR} -where "HASC_${i}='${cod}'" -f "GMT" ${file} ${DIRFRONTERAS}/gadm28_adm${i}.shp
    fi

}


# Función que imprime un mensaje en pantalla junto a la fecha
# Parámetros:
#   $1: Texto del mensaje
function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}


# Función que chequean si existen los grids en un rango de fechas
# Parámetros:
#   $1: fecha de inicio
#   $2: fecha final
#   $3: fecha de pasada
function checkGrids {
    local fecha=$1  #min
    local fechamax=$2  #max
    local fechapasada=$3

    local dataFile

    printMessage "Chequeando que existen grids desde ${fecha} hasta ${fechamax}"
    while [ ${fecha} -le ${fechamax} ]
    do
        dataFile="${DIRNETCDF}/${fechapasada:0:10}/${fecha:0:10}.nc"
        [ ! -f ${dataFile} ] && { rm -rf ${TMPDIR}; echo "Error: No se ha encontrado el fichero ${dataFile}" >&2; exit 1; }
        ln -sf ${dataFile} ${TMPDIR}/${fecha}.nc

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done
}

# Función que procesa los grids en un rango de fechas
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
#   $4: fecha de pasada
function procesarGrids {

    local fecha=$2  #min
    local fechamax=$3  #max
    local vardst=$1
    local fechapasada=$4

    local nargs=$(($#-4))

    for ((i=0; i<=${nargs}; i++))
    do
        varsrc[${i}]=$4
        shift
    done

    dataFileMin="${TMPDIR}/${fecha}_${vardst}.nc"

    zmin=99999
    zmax=-1


    while [ ${fecha} -le ${fechamax} ]
    do
        printMessage "Procesando grid ${vardst}: ${fecha}"

        RGeog ${R} ${J}

        dataFileDST=${TMPDIR}/${fecha}_${vardst}.nc

        for ((i=0; i<=${nargs}; i++))
        do
            dateFileSRC[${i}]=${TMPDIR}/${fecha}_varsrc[${i}].nc
        done

        procesarGrid

        ${GMT} grdproject ${dataFileDST} ${R} ${J} -G${dataFileDST}

        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            ${GMT} grdcut ${dataFileDST} ${RAMP} -G${dataFileDST}   # 275/1080×14,0625=3.5807; 3.5807+2.4688=6.0495; 16.5313+2.4688=20.112
            ${GMT} grdproject ${dataFileDST} -JX${xlength}/${ylength} ${RAMP} -G${dataFileDST} #

        fi
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done



}


# Función que calcula el valor máximo y el valor mínimo entre los grids de un rango de fechas
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
#   $4:
# En la variable zmin se escribe el mínimo y en zmax el máximo
function calcularMinMax {

    local vardst=$1
    local fecha=$2  #min
    local fechamax=$3  #max
    local step=$4

    local zminlocal=999999
    local zmaxlocal=-999999
    zmin=${zminlocal}
    zmax=${zmaxlocal}

    while [ ${fecha} -le ${fechamax} ]
    do

        dataFileDST=${TMPDIR}/${fecha}_${vardst}.nc

        read zminlocal zmaxlocal < <(${GMT} grdinfo ${dataFileDST} -C | awk '{printf "%.0f %.0f\n",$6-0.5,$7+0.5}')
        if [ ${zminlocal} -lt ${zmin} ]
        then
            zmin=${zminlocal}
        fi
        if [ ${zmaxlocal} -gt ${zmax} ]
        then
            zmax=${zmaxlocal}
        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done


}

# Función que genera un frame
# Parámetros:
#   $1: color que se convierte en transparente
#   $2: factor de transparencia a aplicar
function generarFrame {

    local tcolor=$1
    local transparency=$2
    local color2transparent
    local applytransparency

    ${GMT} psbasemap ${R} ${J}  -B+n --PS_MEDIA="${xlength}cx${ylength}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

    printMessage "Generando frame de ${var} para fecha ${fecha}"

    pintarVariable ${tfile}

    [ ! -z ${dpi} ] && E="-E${dpi}"


    ${GMT} psbasemap ${R} ${J} -B+n -O >> ${tmpFile}
    ${GMT} psconvert ${tmpFile} ${E} -P -TG -Qg1 -Qt4

    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

    [ ! -z ${tcolor} ] && [ ${tcolor} != "none" ] && color2transparent="-transparent ${tcolor}"
    [ ! -z ${transparency} ] && (( `echo "${transparency} <  1" | bc -l` )) && \
     applytransparency="-channel A -evaluate multiply ${transparency} +channel"


    ${CONVERT} ${color2transparent} -resize ${xsize}x${ysize}!  ${inputpng} ${applytransparency}  png32:${outputpng}

    cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png
}



# Función que genera los frames de una variable
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
#   $4: minutos en los que se genera un frame
#   $5: color que se convierte en transparente
#   $6: factor de transparencia a aplicar
function generarFrames {
    local var=$1
    local min=$2
    local max=$3
    local mins=$4
    local tcolor=$5
    local transparency=$6

    local fecha=${min}
    local nframe=0

    printMessage "Generando los frames de ${var} desde ${min} hasta ${max} cada ${mins} minutos"
    while [ ${fecha} -le ${max} ]
    do
        tfile=${TMPDIR}/${fecha}_${var}.nc

        tmpFile="${TMPDIR}/${fecha}-${var}.ps"

        if [ ${fecha} -ge ${minreal} ]
        then
            generarFrame ${tcolor} ${transparency}
            nframe=$((${nframe}+1))
        fi
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
    done

}



# Función que genera los frames de una variable
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
#   $4: minutos en los que se interpola un grid
#   $5: salto en horas entre dos grids originales
function interpolarFrames {

    local var=$1
    local min=$2
    local max=$3
    local mins=$4
    local step=$5

    fechaAntMin=`date -u --date="${min:0:8} ${min:8:2} -${step} hours" +%Y%m%d%H%M`
    fileAntMin=${TMPDIR}/${fechaAntMin}_${var}.nc

    if [ ! -f ${fileAntMin} ]
    then

        filemin=${TMPDIR}/${min}_${var}.nc

        fechaSigMin=`date -u --date="${min:0:8} ${min:8:2} +${step} hours" +%Y%m%d%H%M`
        filesigmin=${TMPDIR}/${fechaSigMin}_${var}.nc

        ${GMT} grdmath ${filemin} 2 MUL ${filesigmin} SUB = ${fileAntMin}

    fi

    fechaSigMax=`date -u --date="${max:0:8} ${max:8:2} +${step} hours" +%Y%m%d%H%M`
    fileSigMax=${TMPDIR}/${fechaSigMax}_${var}.nc

    if [ ! -f ${fechaSigMax} ]
    then
        filemax=${TMPDIR}/${max}_${var}.nc
        fechaAntMax=`date -u --date="${max:0:8} ${max:8:2} -${step} hours" +%Y%m%d%H%M`
        fileantmax=${TMPDIR}/${fechaAntMax}_${var}.nc
        ${GMT} grdmath ${filemax} 2 MUL ${fileantmax} SUB = ${fileSigMax}


    fi

    ti=${min}
    nframe=0

    printMessage "Interpolando grids de ${var} desde ${min} hasta ${max} cada ${mins} minutos"
    while [ ${ti} -lt ${max} ]
    do


        # Sacamos los valores a-1, a0, a1 y a2 para hacer la interpolación cúbica
        tfilei=${TMPDIR}/${ti}_${var}.nc

        ti_1=`date -u --date="${ti:0:8} ${ti:8:2} -${step} hours" +%Y%m%d%H%M`
        tfilei_1=${TMPDIR}/${ti_1}_${var}.nc

        ti1=`date -u --date="${ti:0:8} ${ti:8:2} +${step} hours" +%Y%m%d%H%M`
        tfilei1=${TMPDIR}/${ti1}_${var}.nc

        ti2=`date -u --date="${ti:0:8} ${ti:8:2} +$((${step}*2)) hours" +%Y%m%d%H%M`
        tfilei2=${TMPDIR}/${ti2}_${var}.nc

        printMessage "Calculando los grids para hacer interpolaciones cúbicas entre ${ti} y ${ti1}"

        ${GMT} grdmath ${tfilei} ${tfilei} ADD = ${TMPDIR}/a_1.nc
        ${GMT} grdmath ${tfilei1} ${tfilei_1} SUB = ${TMPDIR}/a0.nc
        ${GMT} grdmath ${tfilei_1} 2 MUL ${tfilei} 5 MUL SUB  ${tfilei1} 4 MUL ADD ${tfilei2} SUB = ${TMPDIR}/a1.nc
        ${GMT} grdmath ${tfilei2} ${tfilei_1} SUB  ${tfilei} ${tfilei1} SUB 3 MUL ADD = ${TMPDIR}/a2.nc
        A_1="${TMPDIR}/a_1.nc"
        A0="${TMPDIR}/a0.nc"
        A1="${TMPDIR}/a1.nc"
        A2="${TMPDIR}/a2.nc"

        tmpFile="${TMPDIR}/${fecha}-${var}.ps"

        totalmins=$((${step}*60))
        for((m=${mins}; m<${totalmins}; m+=${mins}))
        do


            # t tiene que ser entre 0 y 1
            t=`awk -v var=${m} -v totalmins=${totalmins} 'BEGIN{printf "%.4f\n",var/totalmins}'`

            fecha=`date -u --date="${ti:0:8} ${ti:8:2} +${m} minutes" +%Y%m%d%H%M`

            tfile=${TMPDIR}/${fecha}_${var}.nc
            tmpFile="${TMPDIR}/${fecha}-${var}.ps"

            printMessage "Interpolando grid ${fecha}"

            # interpolamos el fichero con la formula (a2*t^3 + a1*t^2 + a0*t + a-1)/2
            ${GMT} grdmath ${A_1} ${A0} ${t} MUL ADD ${A1} ${t} 2 POW MUL ADD ${A2} ${t} 3 POW MUL ADD 2 DIV = ${tfile}

        done

        ti=`date -u --date="${ti:0:8} ${ti:8:2} +${step} hours" +%Y%m%d%H%M`
    done

}


# Función que convierte el canal R de los frames de una variable en canal alfa y lo aplica en un fondo blanco
# Parámetros:
#   $1: variable
function black2transparentFrames {

    local var=$1
    printMessage "Convirtiendo canal blanco y negro a canal alfa en frames de ${var}"
    nframe=0
    file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    while [ -f ${file} ]
    do

        ${CONVERT} -size ${xsize}x${ysize} xc:"white" \( ${file} -background black -flatten -channel R -separate +channel \) \
         -compose copy-opacity -composite png32:${file}
         nframe=$((${nframe}+1))
         file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    done

}

# Función que replica los frames de una variable en función del valor de slowmotion
# Parámetros:
#   $1: variable
function replicarFrames {

    local var=$1

    printMessage "Replicando frames de variable ${var}"
    if [ ${slowmotion} -gt 1 ]
    then
        ${FFMPEG} -f image2 -i ${TMPDIR}/${var}%03d.png -threads 1 -filter_complex "setpts=${slowmotion}*PTS+1" -f image2 ${TMPDIR}/kk%03d.png -vsync 1 2>> ${errorsFile} </dev/null
        rm -rf ${TMPDIR}/${var}*.png
        rename -f "s/kk/${var}/" ${TMPDIR}/kk*.png
    fi

    local nframesintermedios=$((${slowmotion}*180/${mins}))
    local nframesintermediosinicio=$((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins}))
    local filtro="loop=$(( ${nframesinicio}+${nframesloop}-${slowmotion} )):1:0"

    local fecha=${min}
    i=0
    while [ ${fecha} -lt ${max} ]
    do
        filtro="loop=$(( ${nframes}-${nframesintermedios} )):1:$((${nframesintermediosinicio}+${nframesintermedios}*${i}))[out];[out]${filtro}"
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        i=$((${i}+1))
    done

    filtro="[0]${filtro}"

    ${FFMPEG} -f image2 -i ${TMPDIR}/${var}%03d.png -threads 1 -filter_complex "${filtro}" -vsync 0 ${TMPDIR}/kk%03d.png 2>> ${errorsFile} </dev/null

    rm -rf ${TMPDIR}/${var}*.png
    rename -f "s/kk/${var}/" ${TMPDIR}/kk*.png
}






# Función que interpola grids de precipitación linealmente dividiendo
# el acumulado de 3 horas entre 3
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
function interpolarPRECLineal {

    local vardst=$1
    local min=$2
    local max=$3

    local acumvar=${variablesprocesar[1]}

    local fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`


    printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada 60 minutos"
    while [ ${fecha} -le ${max} ]
    do
        fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -3 hours" +%Y%m%d%H%M`

        acumFile=${TMPDIR}/${fecha}_${acumvar}.nc
        acumFileAnt=${TMPDIR}/${fechaAnt}_${acumvar}.nc

        acumFileDiff=${TMPDIR}/diff.nc

        ${GMT} grdmath ${acumFile} ${acumFileAnt} SUB 3 DIV = ${acumFileDiff}

        fecha1=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +60 minutes" +%Y%m%d%H%M`
        fecha2=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +120 minutes" +%Y%m%d%H%M`

        printMessage "Interpolando grid ${fecha1}"
        acumFile1=${TMPDIR}/${fecha1}_${acumvar}.nc
        if [ ! -f ${acumFile1} ]
        then
            ${GMT} grdmath ${acumFileDiff} ${acumFileAnt} ADD = ${acumFile1}
        fi


        printMessage "Interpolando grid ${fecha2}"
        acumFile2=${TMPDIR}/${fecha2}_${acumvar}.nc
        if [ ! -f ${acumFile2} ]
        then
            ${GMT} grdmath ${acumFileDiff} 2 MUL ${acumFileAnt} ADD = ${acumFile2}
        fi

        if [ ${esprecacum} -eq 0 ]
        then
            ${GMT} grdmath ${acumFile1} ${acumFileAnt} SUB = ${TMPDIR}/${fecha1}_${vardst}.nc
            ${GMT} grdmath ${acumFile2} ${acumFile1} SUB = ${TMPDIR}/${fecha2}_${vardst}.nc
            ${GMT} grdmath ${acumFile} ${acumFile2} SUB = ${TMPDIR}/${fecha}_${vardst}.nc
        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done

}

# Función que interpola grids de precipitación teniendo también en cuenta la
# tasa de precipitación
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
function interpolarPRECMejorada {

    local vardst=$1
    local min=$2
    local max=$3

    local ratevar=${variablesprocesar[0]}
    local acumvar=${variablesprocesar[1]}

    local fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`

    printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada 60 minutos"
    while [ ${fecha} -le ${max} ]
    do


        fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -3 hours" +%Y%m%d%H%M`

        acumFile=${TMPDIR}/${fecha}_${acumvar}.nc
        acumFileAnt=${TMPDIR}/${fechaAnt}_${acumvar}.nc

        rateFile=${TMPDIR}/${fecha}_${ratevar}.nc
        rateFileAnt=${TMPDIR}/${fechaAnt}_${ratevar}.nc

        fecha05=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:2} +1800 secs" +%Y%m%d%H%M`
        fecha25=`date -u --date="${fecha:0:8} ${fecha:8:2} -1800 secs" +%Y%m%d%H%M`
        acumFile05=${TMPDIR}/${fecha05}_${acumvar}.nc
        acumFile25=${TMPDIR}/${fecha25}_${acumvar}.nc

        ${GMT} grdmath ${acumFileAnt} ${rateFileAnt} 1800 MUL ADD = ${acumFile05}
        ${GMT} grdclip -Sb0/0 ${acumFile05} -G${acumFile05}
        ${GMT} grdmath ${acumFile} ${rateFile} 1800 MUL SUB = ${acumFile25}
        ${GMT} grdclip -Sb0/0 ${acumFile25} -G${acumFile25}

        ${GMT} grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${acumFile05} ${acumFile25} ADD 2 DIV MUL ${acumFile25} DENAN = ${TMPDIR}/kk25.nc
        ${GMT} grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${TMPDIR}/kk25.nc MUL ${acumFile05} DENAN = ${acumFile05}
        mv ${TMPDIR}/kk25.nc ${acumFile25}

        #Acumulado entre el minuto 30 y el 150
        acumFileDiff=${TMPDIR}/diff.nc
        ${GMT} grdmath ${acumFile25} ${acumFile05} SUB = ${acumFileDiff}

        #Acumulado entre el minuto 0 y el 30
        acumFileDiff05=${TMPDIR}/diff05.nc
        ${GMT} grdmath ${acumFile05} ${acumFileAnt} SUB = ${acumFileDiff05}

        #Acumulado entre el minuto 150 y el 180
        acumFileDiff25=${TMPDIR}/diff25.nc
        ${GMT} grdmath ${acumFile} ${acumFile25} SUB = ${acumFileDiff25}

        fileAnt=${acumFileAnt}
        for((m=60; m<180; m+=60))
        do
            secs=$((${m}*60))
            secs1=0
            secs2=0
            secs3=0
            if [ ${secs} -lt 1800 ] # Menor que 30 minutos
            then
                secs1=${secs}
            elif [ ${secs} -lt 9000 ] # Menor que 2 horas y 30 minutos
            then
                secs1=1800
                secs2=$((${secs}-${secs1}))
            else
                secs1=1800
                secs2=7200
                secs3=$((${secs}-${secs1}-${secs2}))
            fi

            fechai=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +${m} minutes" +%Y%m%d%H%M`

            printMessage "Interpolando grid ${fechai}"

            acumFilei=${TMPDIR}/${fechai}_${acumvar}.nc

            if [ ! -f ${acumFilei} ]
            then
                ${GMT} grdmath ${acumFileDiff05} ${secs1} MUL 1800 DIV ${acumFileDiff} ${secs2} MUL 7200 DIV ${acumFileDiff25} ${secs3} MUL 1800 DIV ADD ADD ${acumFileAnt} ADD = ${acumFilei}
            fi

            if [ ${esprecacum} -eq 0 ]
            then
                ${GMT} grdmath ${acumFilei} ${fileAnt} SUB = ${TMPDIR}/${fechai}_${vardst}.nc
                fileAnt=${acumFilei}
            fi

        done

        if [ ${esprecacum} -eq 0 ]
        then
            ${GMT} grdmath ${acumFile} ${fileAnt} SUB = ${TMPDIR}/${fecha}_${vardst}.nc
        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done

    if [ ${esprecacum} -eq 0 ]
    then
        fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
        cp ${TMPDIR}/${fecha}_${vardst}.nc ${TMPDIR}/${min}_${vardst}.nc
    fi

}


# Función que interpola grids de precipitación con interpolación mejorada hasta 72 horas e interpolación lineal después
# Parámetros:
#   $1: variable
#   $2: fecha de inicio
#   $3: fecha final
#   $4: fecha de la pasada
function interpolarPREC {

    local vardst=$1
    local min=$2
    local max=$3
    local fechapasada=$4

    fechalimite=`date -u --date="${fechapasada:0:8} ${fechapasada:8:2} +72 hours" +%Y%m%d%H%M`

    if [ ${min} -lt ${fechalimite} ] && [ ${max} -le ${fechalimite} ]
    then
        interpolarPRECMejorada ${vardst} ${min} ${max}
    elif [ ${min} -ge ${fechalimite} ] && [ ${max} -gt ${fechalimite} ]
    then
        interpolarPRECLineal ${vardst} ${min} ${max}
    else
        interpolarPRECMejorada ${vardst} ${min} ${fechalimite}
        interpolarPRECLineal ${vardst} ${fechalimite} ${max}
    fi

}




#####################################

# Función que pinta unas anotaciones al final de la animación
# Parámetros:
#   $1: archivo de etiquetas
function pintarAnotaciones {

    local fileLabels=$1

    read rotulowidth rotuloheight < <(${CONVERT} ${DIRROTULOS}/rotuloprec/rp000.png -ping -format "%w %h" info:)
    filtro="[1]setpts=0.5*PTS/(25*TB)[rotulo0];[0]copy[out]"
    textos=""
    i=0
    while read line
    do

        lon=`echo ${line} | awk '{print $1}'`
        lat=`echo ${line} | awk '{print $2}'`
        valor=`echo ${line} | awk '{print $3,$4}'`
        x=`awk -v xsize=${xsize} -v x=${lon} -v w=${xlength} -v rw=65  'BEGIN{printf "%d",xsize*x/w - rw }'`
        y=`awk -v ysize=${ysize} -v y=${lat} -v h=${ylength} -v rh=${rotuloheight} 'BEGIN{printf "%d",ysize-ysize*y/h - rh/2 }'`


        xtext=${x}
        ytext=$((${y}+25))

        filtro="${filtro};[rotulo${i}]split[rotulo${i}][rotulo$((${i}+1))]"


        ${CONVERT} -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill ${colorAnotacion} -gravity east -annotate +0+0 "${valor}"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
        textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"

        filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out]; [out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}: enable=gt(n\,22)[out]"

        i=$((${i}+1))

    done < <(sed '$ d' ${fileLabels})

    line=`tail -n 1 ${fileLabels}`

    lon=`echo ${line} | awk '{print $1}'`
    lat=`echo ${line} | awk '{print $2}'`
    valor=`echo ${line} | awk '{print $3,$4}'`
    x=`awk -v xsize=${xsize} -v x=${lon} -v w=${xlength} -v rw=65 'BEGIN{printf "%d",xsize*x/w - rw}'` #rw es la distancia en pixeles desde el pixel 0 hasta el centro del punto
    y=`awk -v ysize=${ysize} -v y=${lat} -v h=${ylength} -v rh=${rotuloheight} 'BEGIN{printf "%d",ysize-ysize*y/h - rh/2 }'`


    xtext=${x}
    ytext=$((${y}+25))


    ${CONVERT} -size ${xsize}x${ysize} xc:transparent png32:${TMPDIR}/transparent.png


    ${CONVERT} -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill ${colorAnotacion} -gravity east -annotate +0+0 "${valor}"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
    textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"
    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}:enable=gt(n\,22)"


    printMessage "Insertando una animación por cada punto calculado"
#    echo $filtro
    ${FFMPEG} -f image2 -i  ${TMPDIR}/transparent.png -f image2  -i ${DIRROTULOS}/rotuloprec/rp%03d.png  ${textos} -threads 1 -filter_complex "${filtro}" -r 25 -y -c:v png -f image2 ${TMPDIR}/anot%03d.png 2>> ${errorsFile} </dev/null

}

# Función que calcula los máximos locales de un grid
# Parámetros:
#   $1: fecha del grid
#   $2: variable
#   $3: límite de maximos
#   $4: umbral por el que por debajo se descartan los máximos
#   $5: código de región. Se descartan los máximos fuera de esa región
# Los máximos se escriben en el archivo Tlabels.txt
function calcularMaximos {

    local fecha=$1
    local var=$2
    local nmax=$3
    local umbral=$4
    local cod=$5


    local dataFile=${TMPDIR}/${fecha}_${var}.nc

    printMessage "Calculando los máximos locales de ${var}"


    ${GMT} grdmath ${dataFile} DUP EXTREMA 2 EQ MUL = ${TMPDIR}/kk
    ${GMT} grdfilter ${TMPDIR}/kk -G${TMPDIR}/kk -Dp -Ffmconv.nc -Np
    ${GMT} grdmath  ${TMPDIR}/kk 0 NAN = ${TMPDIR}/kk


    ${GMT} grd2xyz -s ${TMPDIR}/kk | awk '{printf "%s %s %d\n",$1,$2,int($3+0.5)}' |  awk -v umbral=${umbral} '$3>umbral' | sort -k3 -n -r > ${TMPDIR}/contourlabels.txt



    if [ ! -z ${cod} ]
    then
        buscarFrontera ${TMPDIR}/tmpREG.gmt ${cod}

        comando="cat"
        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            comando="${GMT} mapproject -JX${xlength}c/${ylength}c ${RAMP} -I"
        fi

        cat ${TMPDIR}/contourlabels.txt | ${comando} | ${GMT} mapproject ${JGEOG} ${RGEOG} -I | awk 'BEGIN{print "x,y,z"}{printf "%s,%s,%.0f\n",$1,$2,$3}' > ${TMPDIR}/coords.csv

        filecoord=`echo ${TMPDIR}/coords.csv | sed 's/\//\\\\\//g'`
        sed "s/_FILECOORDS/${filecoord}/" coords.vrt > ${TMPDIR}/coords.vrt
        ${OGR2OGR} -f "ESRI Shapefile" ${TMPDIR}/coords ${TMPDIR}/coords.vrt
        ${OGR2OGR} -f gpkg ${TMPDIR}/merged.gpkg ${TMPDIR}/tmpREG.gmt
        ${OGR2OGR} -f gpkg -append -update ${TMPDIR}/merged.gpkg ${TMPDIR}/coords/output.shp
        ${OGR2OGR} -f csv  ${TMPDIR}/coordsfilter.csv -dialect sqlite -sql "SELECT b.x,b.y,b.z FROM tmpREG a, output b  WHERE contains(a.geom, b.geom)"  ${TMPDIR}/merged.gpkg

        comando="cat"
        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            comando="${GMT} mapproject -JX${xlength}c/${ylength}c ${RAMP}"
        fi

        awk -F "," 'NR>1{print $1,$2,$3}'  ${TMPDIR}/coordsfilter.csv  | tr -d \" | ${GMT} mapproject ${JGEOG} ${RGEOG}|\
         ${comando}  | sort -k3,3 -n -r  > ${TMPDIR}/contourlabels.txt

    fi

    awk '{print $1,$2,$3}'  ${TMPDIR}/contourlabels.txt  |\
     awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} -v ylength=${ylength} -f awk/filtrarintersecciones.awk \
     | head -n ${nmax} > ${TMPDIR}/Tlabels.txt

}


# Función que calcula los mínimos de temperatura en los centros de las danas de gh500
# Parámetros:
#   $1: fecha del grid
# Los mínimos se escriben en el archivo Tlabels.txt
function calcularMinimosDanas {

    local fecha=$1

    local dataFileT=${TMPDIR}/${fecha}_t500.nc
    local dataFileGH=${TMPDIR}/${fecha}_gh500.nc


    printMessage "Calculando los mínimos locales de GH (Centro de las danas)"
    ${GMT} grdcontour ${dataFileGH} ${J} ${R} -A8+t"${TMPDIR}/contourlabels.txt" -T-+a+d20p/1p+lLH -Q100 -Gn1/2c  -C4 > /dev/null
    ${GMT} grdtrack ${TMPDIR}/contourlabels.txt -G${dataFileT} > ${TMPDIR}/kkcontourlabels.txt
    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt

    awk '{if($4=="L") printf "%s %s %.0f\n",$1,$2,$5}' ${TMPDIR}/contourlabels.txt  | awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} -v ylength=${ylength} \
     -f awk/filtrarintersecciones.awk > ${TMPDIR}/Tlabels.txt

}

