#!/bin/bash


#function RGeog {
#
#    proy=`echo ${J} | sed -n 's/\-J\(.\).*/\1/p'`
#    if [ ${R} != "-Rd" ] && ( [ ${proy} == "G" ] || [ ${proy} == "S" ] )
#    then
#        #Ampliamos R para que al pintar el mapa de la variable no se vea recortado por la proyección geográfica
#        w=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$1}'`
#        h=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$2}'`
#        lonmin=`echo 0 ${h} | gmt mapproject -J -R -I | awk '{printf "%.1f",$1}'`
#        lonmed=`echo ${J} | sed -n 's/\-J[GSQ]\(.*\)c/\1/p' | awk -F "/" '{printf "%.1f",$3/2}'`
#        latmax=`echo ${lonmed} ${h} | gmt mapproject -J -R -I | awk '{printf "%.1f",$2+0.5}'`
#
#        latmin1=`echo 0 0 | gmt mapproject -J -R -I | awk '{printf "%.1f",$2-0.5}'`
#        latmin2=`echo ${w} 0 | gmt mapproject -J -R -I | awk '{printf "%.1f",$2-0.5}'`
#        latmin=`awk -v latmin1=${latmin1} -v latmin2=${latmin2} 'BEGIN{print latmin1<latmin2?latmin1:latmin2}'`
#
#        Rgeog=`echo ${R} | sed -n 's/\-R\(.*\)+r/\1/p' | awk -F "/" -v lonmin=${lonmin} -v latmax=${latmax} -v latmin=${latmin} '{printf "-R%s/%s/%s/%s+r",lonmin,latmin,$3,latmax}'`
#    else
#        Rgeog=${R}
#    fi
#}

function RGeog {

    local R=$1
    local J=$2


    proy=`echo ${J} | sed -n 's/\-J\(.\).*/\1/p'`
    if [ ${R} != "-Rd" ] && ( [ ${proy} == "G" ] || [ ${proy} == "S" ] )
    then



        #Ampliamos R para que al pintar el mapa de la variable no se vea recortado por la proyección ortográfica
        w=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$1}'`
        h=`gmt mapproject ${J} ${R} -W | awk '{printf "%f",$2}'`
        lonmin1=`echo 0 ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<0?$1+360:$1)-0.5}'`
        lonmin2=`echo 0 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<0?$1+360:$1)-0.5}'`

        if (( `echo "${lonmin1} < ${lonmin2}" | bc -l` ))
        then
            lonmin=${lonmin1}
        else
            lonmin=${lonmin2}
        fi



        lonmax1=`echo ${w} ${h} | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<0?$1+360:$1)+0.5}'`
        lonmax2=`echo ${w} 0 | gmt mapproject ${J} ${R} -I | awk '{printf "%.1f",($1<0?$1+360:$1)+0.5}'`

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

    else
        Rgeog=${R}
    fi
}





function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}






function procesarGrids {

    fecha=$2  #min
    fechamax=$3  #max
    vardst=$1

    nargs=$(($#-4))

    for ((i=0; i<=${nargs}; i++))
    do
        varsrc[${i}]=$4
        shift
    done

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


        ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc

        procesarGrid

        gmt grdproject ${dataFileDST} ${R} ${J} -G${dataFileDST}

        if [ ! -z ${global} ] && [  ${global} -eq 1 ]
        then
#            read w h < <(gmt mapproject ${J} ${R} -W)

#            ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`

            gmt grdcut ${dataFileDST} ${RAMP} -G${dataFileDST}   # 275/1080×14,0625=3.5807; 3.5807+2.4688=6.0495; 16.5313+2.4688=20.112
            gmt grdproject ${dataFileDST} -JX${xlength}/${ylength} ${RAMP} -G${dataFileDST} #



##            echo $w $h
#            grdcut -R0/${w}/`awk -v w=${w} 'BEGIN{printf "%.4f\n",w-w*0.68}'`/${w} ${dataFileDST} -G${dataFileDST}
##            RAmp=`awk -v w=${w} 'BEGIN{a=(920/1080*w)/2; b=(920/1920*w)/2; printf "-R%.4f/%.4f/%.4f/%.4f\n",-b,w+b,-a,w+a}'`
#            RAmp=`awk -v w=${w} 'BEGIN{h=w*0.68; a=1080*h/1000-h; b=(1920*w/(1000/0.68)-w)/2; printf "-R%.4f/%.4f/%.4f/%.4f\n",-b,w+b,w-w*0.68,w+a}'`
#            hsemi=`awk -v h=${h} 'BEGIN{print h*0.68}'`
#
#            echo $RAmp
#
#            gmt grdproject -JX${w}c/${hsemi}c ${RAmp} ${dataFileDST} -G${dataFileDST}
##            gmt grdedit ${dataFileDST} -R0/${w}/`awk -v h=${h} -v hsemi=${hsemi} 'BEGIN{print h-hsemi}'`/${h}
#
#
##            grdcut -R0/${w}/`awk -v w=${w} 'BEGIN{printf "%.4f\n",w-w*0.68}'`/${w} ${dataFileDST} -G${dataFileDST}
        fi

#        read zminlocal zmaxlocal < <(gmt grdinfo ${dataFileDST} -C | awk '{printf "%.0f %.0f\n",$6-0.5,$7+0.5}')
#        if [ ${zminlocal} -lt ${zmin} ]
#        then
#            zmin=${zminlocal}
#        fi
#        if [ ${zmaxlocal} -gt ${zmax} ]
#        then
#            zmax=${zmaxlocal}
#        fi

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`

    done



}

function calcularMinMax {

    local vardst=$1
    local fecha=$2  #min
    local fechamax=$3  #max
    local step=$4

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
            gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${xlength}cx${ylength}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

            printMessage "Generando frame para fecha ${ti}"

            pintarVariable ${tfile}

            gmt psbasemap -J -R -B+n -O >> ${tmpFile}
            gmt psconvert ${tmpFile}  -P -TG -Qg1 -Qt4

            inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
            outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

            convert -resize ${xsize}x${ysize}!  ${inputpng} png32:${outputpng}

            cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png
}


#function pintarVariable {
#    pintarViento $1
#}

#interpolarFrames "uv" ${min} ${max} ${mins} 3

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


        fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
        tfile=${TMPDIR}/${fecha}_${var}.nc

        tmpFile="${TMPDIR}/${fecha}-${var}.ps"

        if [ ${fecha} -ge ${minreal} ]
        then
            generarFrame
            nframe=$((${nframe}+1))
        fi


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


            if [ ${fecha} -ge ${minreal} ]
            then
                generarFrame
                nframe=$((${nframe}+1))
            fi
        done

        ti=`date -u --date="${ti:0:8} ${ti:8:2} +${step} hours" +%Y%m%d%H%M`
    done



    fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
    tfile=${TMPDIR}/${fecha}_${var}.nc

    tmpFile="${TMPDIR}/${fecha}-${var}.ps"

    if [ ${fecha} -ge ${minreal} ]
    then
        generarFrame
        nframe=$((${nframe}+1))
    fi




}


function black2transparentFrames {

    local var=$1
    printMessage "Convirtiendo canal gris a canal alfa"
    nframe=0
    file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    while [ -f ${file} ]
    do
        convert -size ${xsize}x${ysize} xc:white \( ${file} -channel R -separate +channel \) \
         -compose copy-opacity -composite png32:${file}
         nframe=$((${nframe}+1))
         file="${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png"
    done

}


function replicarFrames {

    var=$1

    if [ ${slowmotion} -gt 1 ]
    then
        ffmpeg -f image2 -i ${TMPDIR}/${var}%03d.png -filter_complex "setpts=${slowmotion}*PTS+1" -f image2 ${TMPDIR}/kk%03d.png -vsync 1
        rm -rf ${TMPDIR}/${var}*.png
        rename -f "s/kk/${var}/" ${TMPDIR}/kk*.png
    fi

    nframesintermedios=$((${slowmotion}*180/${mins}))
    nframesintermediosinicio=$((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins}))
    filtro="loop=$(( ${nframesinicio}+${nframesloop}-${slowmotion} )):1:0"

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

function interpolarPREC {


#    local vardst=$1
#    cp ${TMPDIR}/${min}_acumprec.nc ${TMPDIR}/${min}_prec.nc

    fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
    nframe=0

    local ratevar=${variablesprocesar[0]}
    local acumvar=${variablesprocesar[1]}
    local vardst=$1

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

    if [ ${esprecacum} -eq 0 ] # && [ ${fechapasada} -eq ${min} ]
    then
        fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
        cp ${TMPDIR}/${fecha}_${vardst}.nc ${TMPDIR}/${min}_${vardst}.nc
    fi




}

