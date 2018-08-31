#!/bin/bash

source cfg/spain2.cfg
source estilos/meteored.cfg
source funciones.sh

#titulo="Altura geopotencial a 500hPa"
titulo="NEU PREVISTA"
titulo="PREC. ACUMULADA"
titulo="Precipitación prevista"
#titulo="Nieve acumulada"
#titulo="NEU ACUMULADA"


umbral=0.5

min=201803150000
max=201803160000
#max=201806261500

cptGMT="cpt/precsat.cpt"
#cptGMT="cpt/nievesat2.cpt"

nieve=0

precacum=0

nframerepeat=1

mins=15

OUTPUTS_DIR="/home/juan/Proyectos/pruebas/gmt/OUTPUTS/"
outputFile="${OUTPUTS_DIR}/precprev2.mkv"



TMPDIR="/tmp/`basename $(type $0 | awk '{print $3}').$$`"
#TMPDIR="/tmp/animPREC.sh.12222"
#var="prec"
#R="-R0/25/0/13.7690589662"
#h=14.0625
#J="-JX25c/${h}c"
mkdir -p ${TMPDIR}

errorsFile="${TMPDIR}/errors.txt"
touch ${errorsFile}

awk -v umbral=${umbral} '$1>=umbral' ${cptGMT} > ${TMPDIR}/tmpcpt.cpt
cptGMT="${TMPDIR}/tmpcpt.cpt"



function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}


function pintarMaximosPREC {

#    awk '{print $1,$2,$4" \260C"}' contourlabelsT.txt | gmt pstext -J -R -F+f6p,Helvetica-Bold,black+a0  -Gwhite  -K -O -V >> ${outputFile}
    fecha=$1
    nframe=$2

#    ncFile="${fecha}.nc"
#    variable="t"
#    dataFileT=${TMPDIR}/${fecha}_t.nc
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



function pintarPREC {

    dataFile=$1

    gmt grdimage ${dataFile} -Qg4 -E300 -J -R -C${cptGMT} -nc+c -K -O >> ${tmpFile}

}



printMessage "Generando vídeo de ${titulo}"
printMessage "Fecha mínima: ${min}"
printMessage "Fecha máxima: ${max}"

#fecha=`date -u --date="${min:0:8} ${min:8:2} -3 hours" +%Y%m%d%H%M`
#fechamax=`date -u --date="${max:0:8} ${max:8:2} +6 hours" +%Y%m%d%H%M`
fecha=${min}
fechamax=${max}



zmin=99999
zmax=-1
printMessage "Procesando los grids de Precipitación Acumulada desde ${fecha} hasta ${fechamax}"
#Recortamos los grids a la región seleccionada y transformamos la unidades
while [ ${fecha} -le ${fechamax} ]
do
    printMessage "Procesando grid ${fecha}"
    dataFile=${TMPDIR}/${fecha}_gh.nc

    RGeog
#    echo $Rgeog

#    Rgeog=${R}

    ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc

    ncFile=${TMPDIR}/${fecha}.nc


    ### PRECIPITACIÓN ACUMULADA

    variables="cp lsp"
    if [ ${nieve} -eq 1 ]
    then
        variables="sf"
    fi

    dataFileTotal=`dirname ${ncFile}`/`basename ${ncFile} .nc`_acumprec.nc

    for variable in ${variables}
    do
        dataFile=`dirname ${ncFile}`/`basename ${ncFile} .nc`_${variable}.nc
        if [ ! -f ${dataFile} ]; then

            gmt grdconvert -Rd ${ncFile}\?${variable} ${dataFile}
            gmt grdmath ${dataFile} 1000 MUL = ${dataFile}

#                # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve
#            gmt grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            gmt grdcut ${Rgeog} ${dataFile}  -G${dataFile}
        fi
        if [ ! -f ${dataFileTotal} ]; then
            cp ${dataFile} ${dataFileTotal}
        else
            gmt grdmath ${dataFileTotal} ${dataFile} ADD = ${dataFileTotal}
        fi
    done



    gmt grdproject ${dataFileTotal} ${R} ${J} -G${dataFileTotal} #2> ${errorsFile} ####### CUIDADOOO
    gmt grdsample  ${dataFileTotal} -I${resolucion} -G${dataFileTotal}


    read zminlocal zmaxlocal < <(gmt grdinfo ${dataFileTotal} -C | awk '{printf "%d %d\n",$6,$7}')
    if [ ${zminlocal} -lt ${zmin} ]
    then
        zmin=${zminlocal}
    fi
    if [ ${zmaxlocal} -gt ${zmax} ]
    then
        zmax=${zmaxlocal}
    fi



    ######## Tasa de precipitación ########
    variables="crr lsrr csfr lssfr"
    if [ ${nieve} -eq 1 ]
    then
        variables="csfr lssfr"
    fi

    dataFileTotal=`dirname ${ncFile}`/`basename ${ncFile} .nc`_rateprec.nc

    for variable in ${variables}
    do
        dataFile=`dirname ${ncFile}`/`basename ${ncFile} .nc`_${variable}.nc
#        dataFileAnt=`basename ${ncFileAnt} .nc`_${variable}.nc
        if [ ! -f ${dataFile} ]; then
            # Calculamos el módulo en km/h y cambiamos la proyección a -180/180 quitando los valores menor de 5
        #    gmt grdmath -V ${ncFile}\?${variable} 273.15 SUB = kk
            gmt grdconvert -Rd ${ncFile}\?${variable} ${dataFile}
            #gmt grdmath ${dataFile} 3600 MUL = ${dataFile}

            # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve

#            gmt grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            gmt grdcut ${Rgeog} ${dataFile} -G${dataFile}
            gmt grdclip -Sb0/0 ${dataFile} -G${dataFile}
        fi
        if [ ! -f ${dataFileTotal} ]; then
            cp ${dataFile} ${dataFileTotal}
        else
            gmt grdmath ${dataFileTotal} ${dataFile} ADD = ${dataFileTotal}
        fi
    done

    gmt grdproject ${dataFileTotal} ${R} ${J} -G${dataFileTotal} #2> ${errorsFile} ####### CUIDADOOO
    gmt grdsample  ${dataFileTotal} -I${resolucion} -G${dataFileTotal}

    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
done


if [ ${precacum} -eq 1 ]
then
    printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"
    ./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala.png "mm" 2>> ${errorsFile}
fi

JGEOG=${J}
RGEOG=${R}

read w h < <(gmt mapproject ${J} ${R} -W)
h=14.0625
J="-JX${w}c/${h}c"

R=`grdinfo ${dataFileTotal} -Ir -C` ####

#ti=${min}
fecha=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
nframe=0


#printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada ${mins} minutos"
printMessage "Interpolando grids de PREC desde ${min} hasta ${max} cada 60 minutos"
while [ ${fecha} -le ${max} ]
do


    fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -3 hours" +%Y%m%d%H%M`

    acumFile=${TMPDIR}/${fecha}_acumprec.nc
    acumFileAnt=${TMPDIR}/${fechaAnt}_acumprec.nc

    rateFile=${TMPDIR}/${fecha}_rateprec.nc
    rateFileAnt=${TMPDIR}/${fechaAnt}_rateprec.nc

    fecha05=`date -u --date="${fechaAnt:0:8} ${fechaAnt:8:2} +1800 secs" +%Y%m%d%H%M`
    fecha25=`date -u --date="${fecha:0:8} ${fecha:8:2} -1800 secs" +%Y%m%d%H%M`
    acumFile05=${TMPDIR}/${fecha05}_acumprec.nc
    acumFile25=${TMPDIR}/${fecha25}_acumprec.nc

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

        acumFilei=${TMPDIR}/${fechai}_acumprec.nc

        if [ ! -f ${acumFilei} ]
        then
            gmt grdmath ${acumFileDiff05} ${secs1} MUL 1800 DIV ${acumFileDiff} ${secs2} MUL 7200 DIV ${acumFileDiff25} ${secs3} MUL 1800 DIV ADD ADD ${acumFileAnt} ADD = ${acumFilei}
        fi

    done


    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
done


var="acumprec"
if [ ${precacum} -eq 0 ]
then

    fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
    zmin=99999
    zmax=-1
    printMessage "Generando grids de PREC acumulada horaria desde ${min} hasta ${max} cada 60 minutos"
    while [ ${fecha} -le ${max} ]
    do
        fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -1 hours" +%Y%m%d%H%M`
        printMessage "Generando grid ${fecha}"

        tfile=${TMPDIR}/${fecha}_acumprec.nc
        tfileAnt=${TMPDIR}/${fechaAnt}_acumprec.nc
        gmt grdmath ${tfile} ${tfileAnt} SUB = ${TMPDIR}/${fecha}_prec.nc

        tfile=${TMPDIR}/${fecha}_prec.nc


        read zminlocal zmaxlocal < <(gmt grdinfo ${tfile} -C | awk '{printf "%d %d\n",$6,$7}')
        if [ ${zminlocal} -lt ${zmin} ]
        then
            zmin=${zminlocal}
        fi
        if [ ${zmaxlocal} -gt ${zmax} ]
        then
            zmax=${zmaxlocal}
        fi


        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +1 hours" +%Y%m%d%H%M`
    done

     printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"
    ./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala.png "mm" 2>> ${errorsFile}


    fileMin=${TMPDIR}/${min}_prec.nc

    if [ ! -f ${fileMin} ]
    then

        fechaSigMin=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
        filesigmin=${TMPDIR}/${fechaSigMin}_prec.nc

        fechaSigSigMin=`date -u --date="${min:0:8} ${min:8:2} +2 hours" +%Y%m%d%H%M`
        filesigsigmin=${TMPDIR}/${fechaSigMin}_prec.nc

        gmt grdmath ${filesigmin} 2 MUL ${filesigsigmin} SUB = ${fileMin}
        gmt grdclip -Sb0/0 ${fileMin} -G${fileMin}
    fi

    fechaSigMax=`date -u --date="${max:0:8} ${max:8:2} +1 hours" +%Y%m%d%H%M`
    fileSigMax=${TMPDIR}/${fechaSigMax}_prec.nc

    if [ ! -f ${fechaSigMax} ]
    then
        filemax=${TMPDIR}/${max}_prec.nc
        fechaAntMax=`date -u --date="${max:0:8} ${max:8:2} -1 hours" +%Y%m%d%H%M`
        fileantmax=${TMPDIR}/${fechaAntMax}_prec.nc
        gmt grdmath ${filemax} 2 MUL ${fileantmax} SUB = ${fileSigMax}
        gmt grdclip -Sb0/0 ${fileSigMax} -G${fileSigMax}

    fi


    fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
    printMessage "Generando grids de PREC acumulada horaria desde ${min} hasta ${max} cada ${mins} minutos"
    while [ ${fecha} -lt ${max} ]
    do
    #    fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:2} -1 hours" +%Y%m%d%H%M`

        tfilei=${TMPDIR}/${fecha}_prec.nc

        ti_1=`date -u --date="${fecha:0:8} ${fecha:8:2} -1 hours" +%Y%m%d%H%M`
        ti1=`date -u --date="${fecha:0:8} ${fecha:8:2} +1 hours" +%Y%m%d%H%M`
        ti2=`date -u --date="${fecha:0:8} ${fecha:8:2} +2 hours" +%Y%m%d%H%M`

        tfilei_1=${TMPDIR}/${ti_1}_prec.nc
        tfilei1=${TMPDIR}/${ti1}_prec.nc
        tfilei2=${TMPDIR}/${ti2}_prec.nc

        printMessage "Calculando los grids para hacer interpolaciones cúbicas entre ${fecha} y ${ti1}"

        gmt grdmath ${tfilei} ${tfilei} ADD = ${TMPDIR}/a_1.nc
        gmt grdmath ${tfilei1} ${tfilei_1} SUB = ${TMPDIR}/a0.nc
        gmt grdmath ${tfilei_1} 2 MUL ${tfilei} 5 MUL SUB  ${tfilei1} 4 MUL ADD ${tfilei2} SUB = ${TMPDIR}/a1.nc
        gmt grdmath ${tfilei2} ${tfilei_1} SUB  ${tfilei} ${tfilei1} SUB 3 MUL ADD = ${TMPDIR}/a2.nc
        A_1="${TMPDIR}/a_1.nc"
        A0="${TMPDIR}/a0.nc"
        A1="${TMPDIR}/a1.nc"
        A2="${TMPDIR}/a2.nc"

        for((m=${mins}; m<60; m+=${mins}))
        do

            # t tiene que ser entre 0 y 1
            t=`awk -v var=${m} 'BEGIN{printf "%.4f\n",var/60}'`
    #        mins=`awk -v var=${i} 'BEGIN{printf "%d\n",180*var/30}'`
            fechai=`date -u --date="${fecha:0:8} ${fecha:8:2} +${m} minutes" +%Y%m%d%H%M`

            tfile=${TMPDIR}/${fechai}_prec.nc

            printMessage "Interpolando grid ${fechai}"

            # interpolamos el fichero con la formula (a2*t^3 + a1*t^2 + a0*t + a-1)/2
            gmt grdmath ${A_1} ${A0} ${t} MUL ADD ${A1} ${t} 2 POW MUL ADD ${A2} ${t} 3 POW MUL ADD 2 DIV = ${tfile}
        done


        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +1 hours" +%Y%m%d%H%M`
    done
    var="prec"
fi





fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hour" +%Y%m%d%H%M`
nframe=0

printMessage "Generando los frames de PREC desde ${min} hasta ${max} cada ${mins} minutos"
while [ ${fecha} -le ${max} ]
do

#    fechaAnt=`date -u --date="${fecha:0:8} ${fecha:8:4} -1 hour" +%Y%m%d%H%M`

####    tfile=${TMPDIR}/${fecha}_acumprec.nc
#
    tfile=${TMPDIR}/${fecha}_${var}.nc
#    tfileAnt=${TMPDIR}/${fechaAnt}_acumprec.nc
#    gmt grdmath ${tfile} ${tfileAnt} SUB = ${TMPDIR}/${fecha}_prec.nc
#
#    tfile=${TMPDIR}/${fecha}_prec.nc

    gmt grdclip -Sb${umbral}/NaN ${tfile} -G${tfile}

    tmpFile="${TMPDIR}/${fecha}-acumprec.ps"

    # Sacamos las dimensiones en cm para la proyección dada
    read w h < <(gmt mapproject ${J} ${R} -W)
    gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

    printMessage "Generando frame para fecha ${fecha}"
    pintarPREC ${tfile}

    gmt psbasemap -J -R -B+n -O >> ${tmpFile}
    gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

    convert -resize 1920x1080!  ${inputpng} png32:${outputpng}

    cp ${outputpng} ${TMPDIR}/fb`printf "%03d\n" ${nframe}`.png



    fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`



    nframe=$((${nframe}+1))
done







printMessage "Solapando mapa de fondo en los frames"
# Solapamos las imagenes de isobaras con el fondo de mapa de Europa
ffmpeg  -f image2 -i  ${fondoPNG} -f image2 -i ${TMPDIR}/fb%03d.png  -filter_complex 'overlay'  -y  -c:v png -f image2 ${TMPDIR}/kk%03d.png   2> ${errorsFile} #-frames 106

printMessage "Dibujando fronteras en los frames"
# Solapamos las imagenes de isobaras con el fondo de mapa de Europa
ffmpeg -f image2 -i ${TMPDIR}/kk%03d.png -f image2 -i  ${fronterasPNG}  -filter_complex 'overlay'  -y  -c:v png -f image2 ${TMPDIR}/kk%03d.png 2> ${errorsFile} #-frames 106

# Solapamos las capas con las A y las B
#ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -f image2 -i ${TMPDIR}/f%03d.png -filter_complex 'overlay'  -y -c:v png -f image2 ${TMPDIR}/kkb-%03d.png
# Repetimos el primer frame 30 veces
#ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -filter_complex 'loop=30:1:0'  -y  -c:v png -vsync 0 -f image2 ${TMPDIR}/kkb-%03d.png



#nframesloop=30
##nframesloop=15
#nframesrotulo=26
##nframesrotulo=13
printMessage "Clonando primer frame ${nframesloop} veces"
ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -filter_complex "loop=${nframesloop}:1:0"  -y  -c:v png -vsync 0 -f image2 ${TMPDIR}/kkb-%03d.png 2>> ${errorsFile}


# Insertamos la animación del rotulo
#ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i rotulos/rotulo/fo%03d.png -filter_complex 'overlay= x=25: y=15' -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png

nframefinal=$((${nframe}+${nframesloop}))
if [ ${precacum} -eq 1 ]
then
    printMessage "Insertando animación de los máximos de precipitación acumulada"
    pintarMaximosPREC ${max} $((${nframe}+${nframesloop}))
fi

printMessage "Insertando animación del cartel de los rótulos"
#ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i rotulos/rotuloapunt/r%03d.png -filter_complex 'overlay' -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png 2>> ${errorsFile}
ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i ${framescartel} -filter_complex "overlay= x=${xcartel}: y=${ycartel}" -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png 2>> ${errorsFile}



# Insertamos la animación del fondo del mar
#ffmpeg -i  fondos/fondomar2.mp4 -f image2 -i ${TMPDIR}/kkd-%03d.png -filter_complex '[1:v]loop=-1[kk];[0:v][kk]overlay=shortest=1'  -y ${TMPDIR}/kke-%03d.png





#fecha=${min}
fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hour" +%Y%m%d%H%M`
nframe=0
#repeat=2

# Insertamos los textos

printMessage "Generando frames con los textos de los carteles"

#listFrames="${TMPDIR}/listframes.txt"

for((nframe=1; nframe<${nframesrotulo}; nframe++))
do
#    echo "`printf "%03d\n" ${nframe}`.png" >> ${listFrames}
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
    convert -size 1920x1080 xc:transparent  png32:${outputpng}
done

printMessage "Generando frames con el texto para la fecha ${fecha}"
for((nframe=${nframesrotulo}; nframe<=${nframesloop}; nframe++))
do
#    echo "`printf "%03d\n" ${nframe}`.png" >> ${listFrames}
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
#    rotuloFecha=`LANG=ca_ES@valencia TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`


    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}

#    convert -font Roboto-Bold -pointsize 42 -fill "white" -annotate +112+64 "${titulo}" -page 413x64 -gravity west \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto-Bold -pointsize 32 -fill "white" -annotate +112+133 "${rotuloFecha}" -page 413x55 -gravity west ${outputpng} png32:${outputpng}

done

while [ ${fecha} -le ${max} ]
do

#    for((i=0; i<10; i++))
#    do
#        echo "`printf "%03d\n" ${nframe}`.png" >> ${listFrames}
#    done

    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
#    rotuloFecha=`LANG=ca_ES@valencia TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`


    printMessage "Generando frame con el texto para la fecha ${fecha}"

    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}
#    convert -font Roboto-Bold -pointsize 42 -fill "white" -annotate +112+64 "${titulo}" -page 413x64 -gravity west \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto-Bold -pointsize 32 -fill "white" -annotate +112+133 "${rotuloFecha}" -page 413x55 -gravity west ${outputpng} png32:${outputpng}

    fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
    nframe=$(($nframe+1))

done

outputpng=${TMPDIR}/rotulo-`printf "%03d\n" $((${nframe}-1))`.png
#
#convert -font Roboto-Bold -pointsize 52 -fill "rgb(59,59,59)" -annotate +50+25 "${titulo}" -page 800x152 -gravity northwest \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#convert -font Roboto -pointsize 40 -fill "rgb(59,59,59)" -annotate +50+80 "${rotuloFecha}" -page 800x152 -gravity northwest ${outputpng} png32:${outputpng}

#for((; nframe<=30; nframe++))
#do
#
#done

scaleheight=`convert ${TMPDIR}/escala.png -ping -format "%h" info:`
if [ ${scaleheight} -ge 790 ]
then
    convert ${TMPDIR}/escala.png -resize 85x800\> ${TMPDIR}/escala.png
    scaleheight=790
fi
#composite -geometry +50+$((540-${scaleheight}/2)) ${dir}/escala.png ${file} ${file}

#xscala=50
#xscala=112 #apunt
yscala=$((${yscala}-${scaleheight}/2))
#yscala=$((620-${scaleheight}/2)) # apunt

# Unimos los frames en un fichero de video e insertamos los logos

#'[2]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[0][1]overlay[out];[out][escala]overlay=x=${xscala}:y=${yscala}[out];[out]loop=20:1:151'
printMessage "Uniendo frames de textos con frames de animación y colocando la escala"
nframes=`ls -ltr ${TMPDIR}/kkc-*.png | wc -l`
ffmpeg -f image2 -i ${TMPDIR}/kkc-%03d.png -f image2 -i ${TMPDIR}/rotulo-%03d.png -i  ${TMPDIR}/escala.png -filter_complex "[2]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[0][1]overlay[out];[out][escala]overlay=x=${xscala}:y=${yscala}" -y -c:v png -f image2 ${TMPDIR}/kkd-%03d.png 2> ${errorsFile}
#[out];[out]loop=20:1:$((${nframes}-1))


#ffmpeg -i  fondos/fondomar2.mp4 -f image2 -i ${TMPDIR}/kkd-%03d.png -filter_complex '[1:v]loop=-1[kk];[0:v][kk]overlay=shortest=1'  -y ${TMPDIR}/kke-%03d.png 2> ${errorsFile}
#rename -f 's/kke/kkd/' ${TMPDIR}/kke-*.png


printMessage "Generando video final con logos"

#rename -f 's/kkd/kkc/' ${TMPDIR}/kkd-*.png
#
#
#
#for((nframe=1; nframe<=${nframesloop}; nframe++))
#do
#    cp ${TMPDIR}/kkc-`printf "%03d\n" ${nframe}`.png ${TMPDIR}/kkd-`printf "%03d\n" ${nframe}`.png
#done
#
#fecha=`date -u --date="${min:0:8} ${min:8:2} +1 hour" +%Y%m%d%H%M`
#
#
#nframeout=${nframe}
#while [ ${fecha} -le ${max} ]
#do
#    for((i=0; i<${nframerepeat}; i++,nframeout++))
#    do
#        cp ${TMPDIR}/kkc-`printf "%03d\n" ${nframe}`.png ${TMPDIR}/kkd-`printf "%03d\n" ${nframeout}`.png
#    done
#
#    fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
#    nframe=$(($nframe+1))
#done
#
#
#
#for((; nframe<=${nframes}; nframe++, nframeout++))
#do
#        cp ${TMPDIR}/kkc-`printf "%03d\n" ${nframe}`.png ${TMPDIR}/kkd-`printf "%03d\n" ${nframeout}`.png
#done
#


#ffmpeg -i  fondos/fondomar2.mp4 -f image2 -i ${TMPDIR}/kkd-%03d.png -filter_complex '[1:v]loop=-1[kk];[0:v][kk]overlay=shortest=1'  -y ${TMPDIR}/kke-%03d.png 2> ${errorsFile}

nframerepeat=$((${nframerepeat}+1))
nframes=`ls -ltr ${TMPDIR}/kkd-*.png | wc -l`
#ffmpeg -i ${TMPDIR}/tmp.mkv -f image2 -i logos/esw.png  -f image2 -i logos/ecmwf2.png -filter_complex '[0][1]overlay=25:1000[out];[out][2]overlay=1640:1015' -y ${outputFile}
#ffmpeg -f image2 -i ${TMPDIR}/kkd-%03d.png -f image2 -i logos/logoecmwf.png -filter_complex "[0][1]overlay=1460:955[out];[out]loop=10:1:$((${nframes}-1))" -y ${outputFile} 2>> ${errorsFile}
#ffmpeg -f image2 -i ${TMPDIR}/kkd-%03d.png -f image2 -i logos/logoecmwf.png -i  fondos/fondomar2.mp4 \




logos=""
filtro=""
if [ ${nlogos} -gt 0 ]
then
    logos="-f image2 -i ${logo[0]} "
    filtro="[0][1]overlay=${xlogo[0]}:${ylogo[0]}[out];"
fi

for((nlogo=1; nlogo<${nlogos}; nlogo++))
do
    logos="${logos} -f image2 -i ${logo[${nlogo}]} "
    filtro="${filtro}[out][$((${nlogo}+1))]overlay=${xlogo[${nlogo}]}:${ylogo[${nlogo}]}[out];"
done

filtro="${filtro}[out]loop=10:1:$((${nframes}-1))[out];\
[out]split=3[out0][out1][out2];\
[out0]trim=start_frame=0:end_frame=${nframesloop}[out0];\
[out1]trim=start_frame=$((${nframesloop})):end_frame=$((${nframefinal}))[out1];\
[out1]setpts=${nframerepeat}*PTS-$((${nframesloop}))*${nframerepeat}/(25*TB)[out1];\
[out2]trim=start_frame=$((${nframefinal}))[out2];\
[out2]setpts=PTS-STARTPTS[out2];\
[out0][out1][out2]concat=3[outf];[$((${nlogos}+1))]loop=-1[mar];[mar][outf]overlay=shortest=1"



ffmpeg -f image2 -i ${TMPDIR}/kkd-%03d.png ${logos} -i ${fondomar} \
       -filter_complex "${filtro}" -y ${outputFile} 2>> ${errorsFile}




#       "[0][1]overlay=25:1000[out];[out][2]overlay=1640:1015[out];\
#                        [out]loop=10:1:$((${nframes}-1))[out];\
#                        [out]split=3[out0][out1][out2];\
#                        [out0]trim=start_frame=0:end_frame=${nframesloop}[out0];\
#                        [out1]trim=start_frame=$((${nframesloop})):end_frame=$((${nframefinal}))[out1];\
#                        [out1]setpts=${nframerepeat}*PTS-$((${nframesloop}))*${nframerepeat}/(25*TB)[out1];\
#                        [out2]trim=start_frame=$((${nframefinal}))[out2];\
#                        [out2]setpts=PTS-STARTPTS[out2];\
#                        [out0][out1][out2]concat=3[outf]; [3]loop=-1[mar]; [mar][outf]overlay=shortest=1 \
#                       " -y ${outputFile} #2>> ${errorsFile}

                       #"[0][1]overlay=1460:955[out];\

#[out]loop=5:1:$((${nframes}))[out];\
                       #[out2]setpts=PTS+$((${nframesfinal}-1-${nframesloop}))/(25*TB)[out2];\

#echo nframesloop: ${nframesloop}, nframes: ${nframes}, nframesfinal: ${nframefinal}

                       #

printMessage "Vídeo final generado"

##ffmpeg -y -nostdin -f image2 -i ${OUTPUTS_DIR}/fullhd/f%03d.png -c:v mpeg4 -qscale:v 1 presion.mp4
#ffmpeg -y -nostdin -f image2 -i ${OUTPUTS_DIR}/fullhd/f%03d.png  presion.mkv

rm -rf ${TMPDIR}