#!/bin/bash


function RGeogold {

    proy=`echo ${J} | sed -n 's/\-J\(.\).*/\1/p'`
    if [ ${R} != "-Rd" ] && ( [ ${proy} == "G" ] || [ ${proy} == "S" ] )
    then
        #Ampliamos R para que al pintar el mapa de la variable no se vea recortado por la proyección geográfica
        w=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$1}'`
        h=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$2}'`
        lonmin=`echo 0 ${h} | gmt mapproject -J -R -I | awk '{printf "%.1f",$1}'`
        lonmed=`echo ${J} | sed -n 's/\-J[GSQ]\(.*\)c/\1/p' | awk -F "/" '{printf "%.1f",$3/2}'`
        latmax=`echo ${lonmed} ${h} | gmt mapproject -J -R -I | awk '{printf "%.1f",$2+0.5}'`

        latmin1=`echo 0 0 | gmt mapproject -J -R -I | awk '{printf "%.1f",$2-0.5}'`
        latmin2=`echo ${w} 0 | gmt mapproject -J -R -I | awk '{printf "%.1f",$2-0.5}'`
        latmin=`awk -v latmin1=${latmin1} -v latmin2=${latmin2} 'BEGIN{print latmin1<latmin2?latmin1:latmin2}'`

        Rgeog=`echo ${R} | sed -n 's/\-R\(.*\)+r/\1/p' | awk -F "/" -v lonmin=${lonmin} -v latmax=${latmax} -v latmin=${latmin} '{printf "-R%s/%s/%s/%s+r",lonmin,latmin,$3,latmax}'`
    else
        Rgeog=${R}
    fi
}



function RGeog {

    local R=$1
    local J=$2


    proy=`echo ${J} | sed -n 's/\-J\(.\).*/\1/p'`
    if [ ${R} != "-Rd" ] && ( [ ${proy} == "G" ] || [ ${proy} == "S" ] )
    then



        #Ampliamos R para que al pintar el mapa de la variable no se vea recortado por la proyección ortográfica
        w=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$1}'`
        h=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$2}'`
        lonmin1=`echo 0 ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)-0.5}'`
        lonmin2=`echo 0 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)-0.5}'`

        if (( `echo "${lonmin1} < ${lonmin2}" | bc -l` ))
        then
            lonmin=${lonmin1}
        else
            lonmin=${lonmin2}
        fi



        lonmax1=`echo ${w} ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)+0.5}'`
        lonmax2=`echo ${w} 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<-180?$1+360:$1)+0.5}'`

        if (( `echo "${lonmax1} > ${lonmax2}" | bc -l` ))
        then
            lonmax=${lonmax1}
        else
            lonmax=${lonmax2}
        fi


        lonmed=`awk -v w=${w} 'BEGIN{printf "%.2f",w/2}'`

        latmin1=`echo 0 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`
        latmin2=`echo ${lonmed} 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`
        latmin3=`echo ${w} 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2-0.5}'`

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


        latmax1=`echo 0 ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`
        latmax2=`echo ${lonmed} ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`
        latmax3=`echo ${w} ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",$2+0.5}'`

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
        echo $Rgeog

    elif [ ${R} == "-Rd" ]
    then
        Rgeog=${R}
    else
        Rgeog=`echo ${R} | sed 's/^-R//' | awk -F "/" '{printf "-R%.2f/%.2f/%.2f/%.2f",$1-0.1,$2+0.1,$3-0.1,$4+0.1}'`
#        Rgeog=${R}

    fi
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



function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}





function checkGrids {
    local fecha=$1  #min
    local fechamax=$2  #max
    local fechapasada=$3

    local dataFile

    printMessage "Chequeando que existen grids desde ${fecha} hasta ${fechamax}"
    while [ ${fecha} -le ${fechamax} ]
    do
        dataFile="${DIRNETCDF}/${fechapasada:0:10}/${fecha:0:10}.nc"
        [ ! -f ${dataFile} ] && ( echo "Error: No se ha encontrado el fichero ${dataFile}" >&2; exit 1 )
        ln -sf ${dataFile} ${TMPDIR}/${fecha}.nc

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done
}


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
#    printMessage "Procesando los grids de Viento (U y V) desde ${fecha} hasta ${fechamax}"
    #Recortamos los grids a la región seleccionada y transformamos la unidades
    while [ ${fecha} -le ${fechamax} ]
    do
        printMessage "Procesando grids ${fecha}"


        RGeog ${R} ${J}

        dataFileDST=${TMPDIR}/${fecha}_${vardst}.nc

        for ((i=0; i<=${nargs}; i++))
        do
            dateFileSRC[${i}]=${TMPDIR}/${fecha}_varsrc[${i}].nc
        done


#        ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc
#        ln -sf ${DIRNETCDF}/${fechapasada:0:10}/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc

        procesarGrid

        gmt grdproject ${dataFileDST} ${R} ${J} -G${dataFileDST}

        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            gmt grdcut ${dataFileDST} ${RAMP} -G${dataFileDST}   # 275/1080×14,0625=3.5807; 3.5807+2.4688=6.0495; 16.5313+2.4688=20.112
            gmt grdproject ${dataFileDST} -JX${xlength}/${ylength} ${RAMP} -G${dataFileDST} #

        fi
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done



}

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

        read zminlocal zmaxlocal < <(gmt grdinfo ${dataFileDST} -C | awk '{printf "%.0f %.0f\n",$6-0.5,$7+0.5}')
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


function generarFrame {

    local tcolor
    local color2transparent

    gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${xlength}cx${ylength}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

    printMessage "Generando frame para fecha ${fecha}"

    pintarVariable ${tfile}

    [ ! -z ${dpi} ] && E="-E${dpi}"


    gmt psbasemap -J -R -B+n -O >> ${tmpFile}
    gmt psconvert ${tmpFile} ${E} -P -TG -Qg1 -Qt4

    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

#    echo "tcolor: ${tcolor}"
    [ ! -z ${tcolor} ] && color2transparent="-transparent ${tcolor}"

    convert ${color2transparent} -resize ${xsize}x${ysize}!  ${inputpng} png32:${outputpng}

    cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png
}





function generarFrames {
    local var=$1
    local min=$2
    local max=$3
    local mins=$4
#    local step=$5

    local fecha=${min}
    local nframe=0

    printMessage "Generando los frames de ${var} desde ${min} hasta ${max} cada ${mins} minutos"
    while [ ${fecha} -le ${max} ]
    do

#        fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
        tfile=${TMPDIR}/${fecha}_${var}.nc

        tmpFile="${TMPDIR}/${fecha}-${var}.ps"

        if [ ${fecha} -ge ${minreal} ]
        then
            generarFrame
            nframe=$((${nframe}+1))
        fi
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
    done

}




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

        gmt grdmath ${filemin} 2 MUL ${filesigmin} SUB = ${fileAntMin}

    fi

    fechaSigMax=`date -u --date="${max:0:8} ${max:8:2} +${step} hours" +%Y%m%d%H%M`
    fileSigMax=${TMPDIR}/${fechaSigMax}_${var}.nc

    if [ ! -f ${fechaSigMax} ]
    then
        filemax=${TMPDIR}/${max}_${var}.nc
        fechaAntMax=`date -u --date="${max:0:8} ${max:8:2} -${step} hours" +%Y%m%d%H%M`
        fileantmax=${TMPDIR}/${fechaAntMax}_${var}.nc
        gmt grdmath ${filemax} 2 MUL ${fileantmax} SUB = ${fileSigMax}


    fi


    ti=${min}
    nframe=0


#    printMessage "Generando los frames de Intensidad del Viento (UV) desde ${min} hasta ${max} cada ${mins} minutos"
    printMessage "Generando los frames de ${var} desde ${min} hasta ${max} cada ${mins} minutos"
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

        gmt grdmath ${tfilei} ${tfilei} ADD = ${TMPDIR}/a_1.nc
        gmt grdmath ${tfilei1} ${tfilei_1} SUB = ${TMPDIR}/a0.nc
        gmt grdmath ${tfilei_1} 2 MUL ${tfilei} 5 MUL SUB  ${tfilei1} 4 MUL ADD ${tfilei2} SUB = ${TMPDIR}/a1.nc
        gmt grdmath ${tfilei2} ${tfilei_1} SUB  ${tfilei} ${tfilei1} SUB 3 MUL ADD = ${TMPDIR}/a2.nc
        A_1="${TMPDIR}/a_1.nc"
        A0="${TMPDIR}/a0.nc"
        A1="${TMPDIR}/a1.nc"
        A2="${TMPDIR}/a2.nc"


#        fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
#        tfile=${TMPDIR}/${fecha}_${var}.nc

        tmpFile="${TMPDIR}/${fecha}-${var}.ps"

#        if [ ${fecha} -ge ${minreal} ]
#        then
#            generarFrame
#            nframe=$((${nframe}+1))
#        fi


        # Obtenemos los netcdf intermedios haciendo la interpolación cada mins minutos
    #    for((i=2; i<30; i+=2))
        totalmins=$((${step}*60))
        for((m=${mins}; m<${totalmins}; m+=${mins}))
        do

    #        t=`awk -v var=${i} 'BEGIN{printf "%.4f\n",var/30}'`
    #        mins=`awk -v var=${i} 'BEGIN{printf "%d\n",180*var/30}'`

            # t tiene que ser entre 0 y 1
            t=`awk -v var=${m} -v totalmins=${totalmins} 'BEGIN{printf "%.4f\n",var/totalmins}'`
    #        mins=`awk -v var=${i} 'BEGIN{printf "%d\n",180*var/30}'`
            fecha=`date -u --date="${ti:0:8} ${ti:8:2} +${m} minutes" +%Y%m%d%H%M`

            tfile=${TMPDIR}/${fecha}_${var}.nc
            tmpFile="${TMPDIR}/${fecha}-${var}.ps"

            printMessage "Interpolando grid ${fecha}"

            # interpolamos el fichero con la formula (a2*t^3 + a1*t^2 + a0*t + a-1)/2
            gmt grdmath ${A_1} ${A0} ${t} MUL ADD ${A1} ${t} 2 POW MUL ADD ${A2} ${t} 3 POW MUL ADD 2 DIV = ${tfile}


#            if [ ${fecha} -ge ${minreal} ]
#            then
#                generarFrame
#                nframe=$((${nframe}+1))
#            fi
        done

        ti=`date -u --date="${ti:0:8} ${ti:8:2} +${step} hours" +%Y%m%d%H%M`
    done



#    fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
#    tfile=${TMPDIR}/${fecha}_${var}.nc
#
#    tmpFile="${TMPDIR}/${fecha}-${var}.ps"

#    if [ ${fecha} -ge ${minreal} ]
#    then
#        generarFrame
#        nframe=$((${nframe}+1))
#    fi




}


function black2transparentFrames {

    local var=$1
    printMessage "Convirtiendo canal gris a canal alfa"
    nframe=0
    file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    while [ -f ${file} ]
    do
        convert -size ${xsize}x${ysize} xc:"white" \( ${file} -background black -flatten -channel R -separate +channel \) \
         -compose copy-opacity -composite png32:${file}
         nframe=$((${nframe}+1))
         file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    done

}


function replicarFrames {

    local var=$1

    if [ ${slowmotion} -gt 1 ]
    then
        ffmpeg -f image2 -i ${TMPDIR}/${var}%03d.png -filter_complex "setpts=${slowmotion}*PTS+1" -f image2 ${TMPDIR}/kk%03d.png -vsync 1
        rm -rf ${TMPDIR}/${var}*.png
        rename -f "s/kk/${var}/" ${TMPDIR}/kk*.png
    fi

    local nframesintermedios=$((${slowmotion}*180/${mins}))
    local nframesintermediosinicio=$((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins}))
    local filtro="loop=$(( ${nframesinicio}+${nframesloop}-${slowmotion} )):1:0"

    fecha=${min}
    i=0
    while [ ${fecha} -lt ${max} ]
    do
        filtro="loop=$(( ${nframes}-${nframesintermedios} )):1:$((${nframesintermediosinicio}+${nframesintermedios}*${i}))[out];[out]${filtro}"
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        i=$((${i}+1))
    done

    filtro="[0]${filtro}"
#    if [ ${slowmotion} -ne 1 ]
#    then
#        filtro="[0]setpts=${slowmotion}*PTS[out];[out]${filtro}"
#        vsyncoption="-vsync 1"
#    else
#        filtro="[0]${filtro}"
#        vsyncoption="-vsync 0"
#    fi

    echo ${filtro}
#    exit

    ffmpeg -f image2 -i ${TMPDIR}/${var}%03d.png -filter_complex "${filtro}" -vsync 0 ${TMPDIR}/kk%03d.png

    rm -rf ${TMPDIR}/${var}*.png
    rename -f "s/kk/${var}/" ${TMPDIR}/kk*.png
}







function interpolarPRECLineal {

    local vardst=$1
    local min=$2
    local max=$3
#    local fechapasada=$4

#    local ratevar=${variablesprocesar[0]}
    local acumvar=${variablesprocesar[1]}

    local fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
#    local nframe=0

    #printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada ${mins} minutos"
    printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada 60 minutos"
    while [ ${fecha} -le ${max} ]
    do
        fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -3 hours" +%Y%m%d%H%M`

        acumFile=${TMPDIR}/${fecha}_${acumvar}.nc
        acumFileAnt=${TMPDIR}/${fechaAnt}_${acumvar}.nc

        acumFileDiff=${TMPDIR}/diff.nc

        gmt grdmath ${acumFile} ${acumFileAnt} SUB 3 DIV = ${acumFileDiff}

        fecha1=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +60 minutes" +%Y%m%d%H%M`
        fecha2=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +120 minutes" +%Y%m%d%H%M`

        printMessage "Interpolando grid ${fecha1}"
        acumFile1=${TMPDIR}/${fecha1}_${acumvar}.nc
        if [ ! -f ${acumFile1} ]
        then
            gmt grdmath ${acumFileDiff} ${acumFileAnt} ADD = ${acumFile1}
        fi


        printMessage "Interpolando grid ${fecha2}"
        acumFile2=${TMPDIR}/${fecha2}_${acumvar}.nc
        if [ ! -f ${acumFile2} ]
        then
            gmt grdmath ${acumFileDiff} 2 MUL ${acumFileAnt} ADD = ${acumFile2}
        fi

        if [ ${esprecacum} -eq 0 ]
        then
            gmt grdmath ${acumFile1} ${acumFileAnt} SUB = ${TMPDIR}/${fecha1}_${vardst}.nc
            gmt grdmath ${acumFile2} ${acumFile1} SUB = ${TMPDIR}/${fecha2}_${vardst}.nc
            gmt grdmath ${acumFile} ${acumFile2} SUB = ${TMPDIR}/${fecha}_${vardst}.nc
        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done

}

function interpolarPRECMejorada {

    local vardst=$1
    local min=$2
    local max=$3
#    local fechapasada=$4

    local ratevar=${variablesprocesar[0]}
    local acumvar=${variablesprocesar[1]}

    local fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
#    local nframe=0

    #printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada ${mins} minutos"
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

        gmt grdmath ${acumFileAnt} ${rateFileAnt} 1800 MUL ADD = ${acumFile05}
        gmt grdclip -Sb0/0 ${acumFile05} -G${acumFile05}
        gmt grdmath ${acumFile} ${rateFile} 1800 MUL SUB = ${acumFile25}
        gmt grdclip -Sb0/0 ${acumFile25} -G${acumFile25}

        gmt grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${acumFile05} ${acumFile25} ADD 2 DIV MUL ${acumFile25} DENAN = ${TMPDIR}/kk25.nc
        gmt grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${TMPDIR}/kk25.nc MUL ${acumFile05} DENAN = ${acumFile05}
        mv ${TMPDIR}/kk25.nc ${acumFile25}

        #Acumulado entre el minuto 30 y el 150
        acumFileDiff=${TMPDIR}/diff.nc
        gmt grdmath ${acumFile25} ${acumFile05} SUB = ${acumFileDiff}

        #Acumulado entre el minuto 0 y el 30
        acumFileDiff05=${TMPDIR}/diff05.nc
        gmt grdmath ${acumFile05} ${acumFileAnt} SUB = ${acumFileDiff05}

        #Acumulado entre el minuto 150 y el 180
        acumFileDiff25=${TMPDIR}/diff25.nc
        gmt grdmath ${acumFile} ${acumFile25} SUB = ${acumFileDiff25}

        fileAnt=${acumFileAnt}
    #    for((m=${mins}; m<180; m+=${mins}))
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
                gmt grdmath ${acumFileDiff05} ${secs1} MUL 1800 DIV ${acumFileDiff} ${secs2} MUL 7200 DIV ${acumFileDiff25} ${secs3} MUL 1800 DIV ADD ADD ${acumFileAnt} ADD = ${acumFilei}
            fi

            if [ ${esprecacum} -eq 0 ]
            then
                gmt grdmath ${acumFilei} ${fileAnt} SUB = ${TMPDIR}/${fechai}_${vardst}.nc
                fileAnt=${acumFilei}
            fi

        done

        if [ ${esprecacum} -eq 0 ]
        then
            gmt grdmath ${acumFile} ${fileAnt} SUB = ${TMPDIR}/${fecha}_${vardst}.nc
        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done

    if [ ${esprecacum} -eq 0 ]
    then
        fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
        cp ${TMPDIR}/${fecha}_${vardst}.nc ${TMPDIR}/${min}_${vardst}.nc
    fi

}



function interpolarPREC {


#    local vardst=$1
#    cp ${TMPDIR}/${min}_acumprec.nc ${TMPDIR}/${min}_prec.nc
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




#    local ratevar=${variablesprocesar[0]}
#    local acumvar=${variablesprocesar[1]}
#
#    local fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
#    local nframe=0
#
#    #printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada ${mins} minutos"
#    printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada 60 minutos"
#    while [ ${fecha} -le ${max} ]
#    do
#
#
#        fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -3 hours" +%Y%m%d%H%M`
#
#        acumFile=${TMPDIR}/${fecha}_${acumvar}.nc
#        acumFileAnt=${TMPDIR}/${fechaAnt}_${acumvar}.nc
#
#        rateFile=${TMPDIR}/${fecha}_${ratevar}.nc
#        rateFileAnt=${TMPDIR}/${fechaAnt}_${ratevar}.nc
#
#        fecha05=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:2} +1800 secs" +%Y%m%d%H%M`
#        fecha25=`date -u --date="${fecha:0:8} ${fecha:8:2} -1800 secs" +%Y%m%d%H%M`
#        acumFile05=${TMPDIR}/${fecha05}_${acumvar}.nc
#        acumFile25=${TMPDIR}/${fecha25}_${acumvar}.nc
#
#        gmt grdmath ${acumFileAnt} ${rateFileAnt} 1800 MUL ADD = ${acumFile05}
#        gmt grdclip -Sb0/0 ${acumFile05} -G${acumFile05}
#        gmt grdmath ${acumFile} ${rateFile} 1800 MUL SUB = ${acumFile25}
#        gmt grdclip -Sb0/0 ${acumFile25} -G${acumFile25}
#
#        gmt grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${acumFile05} ${acumFile25} ADD 2 DIV MUL ${acumFile25} DENAN = ${TMPDIR}/kk25.nc
#        gmt grdmath ${acumFile25} ${acumFile05} LT 0 NAN ${TMPDIR}/kk25.nc MUL ${acumFile05} DENAN = ${acumFile05}
#        mv ${TMPDIR}/kk25.nc ${acumFile25}
#
#        #Acumulado entre el minuto 30 y el 150
#        acumFileDiff=${TMPDIR}/diff.nc
#        gmt grdmath ${acumFile25} ${acumFile05} SUB = ${acumFileDiff}
#
#        #Acumulado entre el minuto 0 y el 30
#        acumFileDiff05=${TMPDIR}/diff05.nc
#        gmt grdmath ${acumFile05} ${acumFileAnt} SUB = ${acumFileDiff05}
#
#        #Acumulado entre el minuto 150 y el 180
#        acumFileDiff25=${TMPDIR}/diff25.nc
#        gmt grdmath ${acumFile} ${acumFile25} SUB = ${acumFileDiff25}
#
#        fileAnt=${acumFileAnt}
#    #    for((m=${mins}; m<180; m+=${mins}))
#        for((m=60; m<180; m+=60))
#        do
#            secs=$((${m}*60))
#            secs1=0
#            secs2=0
#            secs3=0
#            if [ ${secs} -lt 1800 ] # Menor que 30 minutos
#            then
#                secs1=${secs}
#            elif [ ${secs} -lt 9000 ] # Menor que 2 horas y 30 minutos
#            then
#                secs1=1800
#                secs2=$((${secs}-${secs1}))
#            else
#                secs1=1800
#                secs2=7200
#                secs3=$((${secs}-${secs1}-${secs2}))
#            fi
#
#            fechai=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:4} +${m} minutes" +%Y%m%d%H%M`
#
#            printMessage "Interpolando grid ${fechai}"
#
#            acumFilei=${TMPDIR}/${fechai}_${acumvar}.nc
#
#            if [ ! -f ${acumFilei} ]
#            then
#                gmt grdmath ${acumFileDiff05} ${secs1} MUL 1800 DIV ${acumFileDiff} ${secs2} MUL 7200 DIV ${acumFileDiff25} ${secs3} MUL 1800 DIV ADD ADD ${acumFileAnt} ADD = ${acumFilei}
#            fi
#
#            if [ ${esprecacum} -eq 0 ]
#            then
#                gmt grdmath ${acumFilei} ${fileAnt} SUB = ${TMPDIR}/${fechai}_${vardst}.nc
#                fileAnt=${acumFilei}
#            fi
#
#        done
#
#        if [ ${esprecacum} -eq 0 ]
#        then
#            gmt grdmath ${acumFile} ${fileAnt} SUB = ${TMPDIR}/${fecha}_${vardst}.nc
#        fi
#
#        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
#    done
#
#    if [ ${esprecacum} -eq 0 ]
#    then
#        fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
#        cp ${TMPDIR}/${fecha}_${vardst}.nc ${TMPDIR}/${min}_${vardst}.nc
#    fi
}













#####################################





function pintarAnotaciones {

    local fileLabels=$1

    read rotulowidth rotuloheight < <(convert rotulos/rotuloprec/rp000.png -ping -format "%w %h" info:)
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


        convert -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill ${colorAnotacion} -gravity east -annotate +0+0 "${valor}"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
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


    convert -size ${xsize}x${ysize} xc:transparent png32:${TMPDIR}/transparent.png


    convert -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill ${colorAnotacion} -gravity east -annotate +0+0 "${valor}"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
    textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"
    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}:enable=gt(n\,22)"


    printMessage "Insertando una animación por cada punto calculado"
    echo $filtro
    ffmpeg -f image2 -i  ${TMPDIR}/transparent.png -f image2  -i rotulos/rotuloprec/rp%03d.png  ${textos} -filter_complex "${filtro}" -r 25 -y -c:v png -f image2 ${TMPDIR}/anot%03d.png #2> ${errorsFile}


}


function calcularMaximos {

    local fecha=$1
    local var=$2
    local nmax=$3
    local umbral=$4
    local cod=$5


    local dataFile=${TMPDIR}/${fecha}_${var}.nc

    printMessage "Calculando los máximos locales de ${var}"


    gmt grdmath ${dataFile} DUP EXTREMA 2 EQ MUL = ${TMPDIR}/kk
    gmt grdfilter ${TMPDIR}/kk -G${TMPDIR}/kk -Dp -Ffmconv.nc -Np
    gmt grdmath  ${TMPDIR}/kk 0 NAN = ${TMPDIR}/kk


    gmt grd2xyz -s ${TMPDIR}/kk | awk '{printf "%s %s %d\n",$1,$2,int($3+0.5)}' |  awk -v umbral=${umbral} '$3>umbral' | sort -k3 -n -r > ${TMPDIR}/contourlabels.txt



    if [ ! -z ${cod} ]
    then
        buscarFrontera ${TMPDIR}/tmpREG.gmt ${cod}

        comando="cat"
        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            comando="gmt mapproject -JX${xlength}c/${ylength}c ${RAMP} -I"
        fi

        cat ${TMPDIR}/contourlabels.txt | ${comando} | gmt mapproject ${JGEOG} ${RGEOG} -I | awk 'BEGIN{print "x,y,z"}{printf "%s,%s,%.0f\n",$1,$2,$3}' > ${TMPDIR}/coords.csv

        filecoord=`echo ${TMPDIR}/coords.csv | sed 's/\//\\\\\//g'`
        sed "s/_FILECOORDS/${filecoord}/" coords.vrt > ${TMPDIR}/coords.vrt
        ogr2ogr -f "ESRI Shapefile" ${TMPDIR}/coords ${TMPDIR}/coords.vrt
#        ogr2ogr -f gpkg ${TMPDIR}/merged.gpkg fronteras/gadm28_adm0.shp -where "ISO2='${cod}'"
        ogr2ogr -f gpkg ${TMPDIR}/merged.gpkg ${TMPDIR}/tmpREG.gmt
        ogr2ogr -f gpkg -append -update ${TMPDIR}/merged.gpkg ${TMPDIR}/coords/output.shp
        ogr2ogr -f csv ${TMPDIR}/coordsfilter.csv -dialect sqlite -sql "SELECT b.x,b.y,b.z FROM tmpREG a, output b  WHERE contains(a.geom, b.geom)"  ${TMPDIR}/merged.gpkg

        comando="cat"
        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
            comando="gmt mapproject -JX${xlength}c/${ylength}c ${RAMP}"
        fi

        awk -F "," 'NR>1{print $1,$2,$3}'  ${TMPDIR}/coordsfilter.csv  | gmt mapproject ${JGEOG} ${RGEOG}|\
         ${comando}  | sort -k3,3 -n -r  > ${TMPDIR}/contourlabels.txt

    fi

    awk '{print $1,$2,$3}'  ${TMPDIR}/contourlabels.txt  |\
     awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} -v ylength=${ylength} -f filtrarintersecciones.awk \
     | head -n ${nmax} > ${TMPDIR}/Tlabels.txt






}


#
#function calcularMinimos {
#
#    local fecha=$1
#    local var=$2
#    local nmax=$3
#    local umbral=$4
#    local cod=$5
#
#
#    local dataFile=${TMPDIR}/${fecha}_${var}.nc
#
#    printMessage "Calculando los MÍNIMOS locales de ${var}"
#
#
#    gmt grdmath ${dataFile} DUP EXTREMA -2 EQ MUL = ${TMPDIR}/kk
#    gmt grdfilter ${TMPDIR}/kk -G${TMPDIR}/kk -Dp -Ffmconv.nc -Np
#    gmt grdmath  ${TMPDIR}/kk 0 NAN = ${TMPDIR}/kk
#
#
#    gmt grd2xyz -s ${TMPDIR}/kk | awk '{printf "%s %s %d\n",$1,$2,int($3+0.5)}' |  awk -v umbral=${umbral} '$3<umbral' | sort -k3 -n > ${TMPDIR}/contourlabels.txt
#
#
#
#    if [ ! -z ${cod} ]
#    then
#        buscarFrontera ${TMPDIR}/tmpREG.gmt ${cod}
#
#        comando="cat"
#        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
#        then
#            comando="gmt mapproject -JX${xlength}c/${ylength}c ${RAMP} -I"
#        fi
#
#        cat ${TMPDIR}/contourlabels.txt | ${comando} | gmt mapproject ${JGEOG} ${RGEOG} -I | awk 'BEGIN{print "x,y,z"}{printf "%s,%s,%.0f\n",$1,$2,$3}' > ${TMPDIR}/coords.csv
#
#        filecoord=`echo ${TMPDIR}/coords.csv | sed 's/\//\\\\\//g'`
#        sed "s/_FILECOORDS/${filecoord}/" coords.vrt > ${TMPDIR}/coords.vrt
#        ogr2ogr -f "ESRI Shapefile" ${TMPDIR}/coords ${TMPDIR}/coords.vrt
##        ogr2ogr -f gpkg ${TMPDIR}/merged.gpkg fronteras/gadm28_adm0.shp -where "ISO2='${cod}'"
#        ogr2ogr -f gpkg ${TMPDIR}/merged.gpkg ${TMPDIR}/tmpREG.gmt
#        ogr2ogr -f gpkg -append -update ${TMPDIR}/merged.gpkg ${TMPDIR}/coords/output.shp
#        ogr2ogr -f csv ${TMPDIR}/coordsfilter.csv -dialect sqlite -sql "SELECT b.x,b.y,b.z FROM tmpREG a, output b  WHERE contains(a.geom, b.geom)"  ${TMPDIR}/merged.gpkg
#
#        comando="cat"
#        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
#        then
#            comando="gmt mapproject -JX${xlength}c/${ylength}c ${RAMP}"
#        fi
#
#        awk -F "," 'NR>1{print $1,$2,$3}'  ${TMPDIR}/coordsfilter.csv  | gmt mapproject ${JGEOG} ${RGEOG}|\
#         ${comando}  | sort -k3,3 -n   > ${TMPDIR}/contourlabels.txt
#
#    fi
#
#    awk '{print $1,$2,$3}'  ${TMPDIR}/contourlabels.txt  |\
#     awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} -v ylength=${ylength} -f filtrarintersecciones.awk \
#     | head -n ${nmax} > ${TMPDIR}/Tlabels.txt
#
#
#
#
#
#
#}



function calcularMinimosDanas {

    local fecha=$1

    local dataFileT=${TMPDIR}/${fecha}_t500.nc
    local dataFileGH=${TMPDIR}/${fecha}_gh500.nc


    printMessage "Calculando los mínimos locales de GH (Centro de las danas)"
    gmt grdcontour ${dataFileGH} ${J} ${R} -A8+t"${TMPDIR}/contourlabels.txt" -T-+a+d20p/1p+lLH -Q100 -Gn1/2c  -C4 > /dev/null
    gmt grdtrack ${TMPDIR}/contourlabels.txt -G${dataFileT} > ${TMPDIR}/kkcontourlabels.txt
    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt

    awk '{if($4=="L") printf "%s %s %.0f\n",$1,$2,$5}' ${TMPDIR}/contourlabels.txt  | awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} -v ylength=${ylength} \
     -f filtrarintersecciones.awk > ${TMPDIR}/Tlabels.txt

}











function pintarMaximosPREC {


    fecha=$1
    nframe=$2


    dataFile=${TMPDIR}/${fecha}_acumprec.nc

    printMessage "Calculando los máximos locales de la precipitación"

#    ogr2ogr -where "ISO2='ES'" -f "GMT" ${TMPDIR}/tmpREG0.gmt fronteras/gadm28_adm0.shp
    gmt pscoast -EES -M > ${TMPDIR}/tmpREG0.gmt


    gmt grdcontour ${dataFile} ${J} ${R} -A100+t"${TMPDIR}/contourlabels.txt" -T++a+d20p/1p+lLH -Q100 -Gn1/2c  -C10 > /dev/null
    gmt grdtrack ${TMPDIR}/contourlabels.txt -G${dataFile} > ${TMPDIR}/kkcontourlabels.txt
    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt

#    read w h < <(gmt grdinfo -C ${dataFile} | awk '{print $3,$5}')
    read w h < <(gmt mapproject -R -J -W)

    cat ${TMPDIR}/contourlabels.txt | gmt mapproject ${JGEOG} ${RGEOG} -I | awk 'BEGIN{print "x,y,z"}{if($4=="H") printf "%s,%s,%.0f\n",$1,$2,$5}' > ${TMPDIR}/coords.csv

    filecoord=`echo ${TMPDIR}/coords.csv | sed 's/\//\\\\\//g'`
    sed "s/_FILECOORDS/${filecoord}/" coords.vrt > ${TMPDIR}/coords.vrt
    ogr2ogr -f "ESRI Shapefile" ${TMPDIR}/coords ${TMPDIR}/coords.vrt
    ogr2ogr -f gpkg ${TMPDIR}/merged.gpkg fronteras/gadm28_adm0.shp -where "ISO2='ES'"
    ogr2ogr -f gpkg -append -update ${TMPDIR}/merged.gpkg ${TMPDIR}/coords/output.shp
    ogr2ogr -f csv ${TMPDIR}/coordsfilter.csv -dialect sqlite -sql "SELECT b.x,b.y,b.z FROM gadm28_adm0 a, output b  WHERE contains(a.geom, b.geom)"  ${TMPDIR}/merged.gpkg


    ########### HAY QUE QUITAR EL MAPPROJECT CUANDO SE REPROYECTEN LOS GRIDS !!!!!!
#    awk '{if($4=="H") printf "%s %s %.0f\n",$1,$2,$5}' ${TMPDIR}/contourlabels.txt | sort -k3,3 -n -r | head -n 15 | gmt mapproject -R -J > ${TMPDIR}/Tlabels.txt
    awk -F "," 'NR>1{print $1,$2,$3}'  ${TMPDIR}/coordsfilter.csv  | sort -k3,3 -n -r | gmt mapproject ${JGEOG} ${RGEOG} | awk  -f filtrarintersecciones.awk  | head -n 10 > ${TMPDIR}/Tlabels.txt





    read rotulowidth rotuloheight < <(convert rotulos/rotuloprec/rp000.png -ping -format "%w %h" info:)
    filtro="[1]setpts=0.5*PTS+${nframe}/(25*TB)[rotulo0];[0]copy[out]"
    textos=""
    i=0
    while read line
    do
        #echo $line
        lon=`echo ${line} | awk '{print $1}'`
        lat=`echo ${line} | awk '{print $2}'`
        t=`echo ${line} | awk '{print $3}'`
        x=`awk -v x=${lon} -v w=${w} -v rw=65  'BEGIN{printf "%d",1920*x/w - rw }'`
        y=`awk -v y=${lat} -v h=${h} -v rh=${rotuloheight} 'BEGIN{printf "%d",1080-1080*y/h - rh/2 }'`
#        if [ ${y} -lt 0 ]
#        then
#
#        fi


        xtext=${x}
        ytext=$((${y}+25))

        filtro="${filtro};[rotulo${i}]split[rotulo${i}][rotulo$((${i}+1))]"
#        if [ ${y} -lt 0 ]
#        then
#            filtro="${filtro};[rotulo${i}]vflip[rotulo${i}]"
#            y=`awk -v y=${lat} -v h=${h}  'BEGIN{printf "%d",1080-1080*y/h}'`
#            ytext=$((${y}+18+65))
#        fi

#        convert -font Roboto-Bold  -pointsize 26 -fill "white" -annotate +0+0 "${t}mm" -gravity east \( -size 180x50 xc:transparent \) \( +clone -background gray -shadow 80x2+1+1 -crop 180x50+0+0 \) +swap -composite png32:${TMPDIR}/t${i}.png
        convert -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill "white" -gravity east -annotate +0+0 "${t}mm"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
        textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"

        filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out]; [out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}: enable=gt(n\,$((${nframe}+22)))[out]"
#        filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out]; [out]drawtext=fontsize=30:fontfile=Roboto-Bold.ttf:text=\'${t} mm\':x=${xtext}:y=${ytext}:enable=gt(n\,$((${nframe}+22)))[out]"

        i=$((${i}+1))

#        rename -f 's/kkd/kkc/' ${TMPDIR}/kkd-*.png

    done < <(sed '$ d' ${TMPDIR}/Tlabels.txt)

    line=`tail -n 1 ${TMPDIR}/Tlabels.txt`

    lon=`echo ${line} | awk '{print $1}'`
    lat=`echo ${line} | awk '{print $2}'`
    t=`echo ${line} | awk '{print $3}'`
    x=`awk -v x=${lon} -v w=${w} -v rw=65 'BEGIN{printf "%d",1920*x/w - rw}'` #rw es la distancia en pixeles desde el pixel 0 hasta el centro del punto
    y=`awk -v y=${lat} -v h=${h} -v rh=${rotuloheight} 'BEGIN{printf "%d",1080-1080*y/h - rh/2 }'`


    xtext=${x}
    ytext=$((${y}+25))
#    if [ ${y} -lt 0 ]
#    then
#        filtro="${filtro};[rotulo${i}]vflip[rotulo${i}]"
#        y=`awk -v y=${lat} -v h=${h}  'BEGIN{printf "%d",1080-1080*y/h}'`
#        ytext=$((${y}+18+65))
#    fi

#    convert -font Roboto-Bold  -pointsize 26 -fill "white" -annotate +0+0 "${t}mm" -gravity east \( -size 180x50 xc:transparent \) \( +clone -background gray -shadow 80x2+1+1 -crop 180x50+0+0 \) +swap -composite png32:${TMPDIR}/t${i}.png
    convert -size 180x50 xc:none -font Roboto-Bold  -pointsize 26 -fill "white" -gravity east -annotate +0+0 "${t}mm"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 180x50+0+0 png32:${TMPDIR}/t${i}.png
    textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"
    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}:enable=gt(n\,$((${nframe}+22)))"
#    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out]drawtext=fontsize=30:fontfile=Roboto-Bold.ttf:text=\'${t} mm\':x=${xtext}:y=${ytext}:enable=gt(n\,$((${nframe}+22)))"

    printMessage "Insertando una animación por cada punto calculado"
    ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i rotulos/rotuloprec/rp%03d.png  ${textos} -filter_complex "${filtro}" -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png 2> ${errorsFile}
    rename -f 's/kkc/kkb/' ${TMPDIR}/kkc-*.png

}




