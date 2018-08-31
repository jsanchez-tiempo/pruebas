#!/bin/bash

source cfg/europa2.cfg
source funciones.sh
source estilos/apunt.cfg

color="white"
disobaras=5
detiquetas=10

#titulo="Altura geopotencial a 500hPa"
titulo="CAPA DE 500HPA"

#normalmsl=1013
#rango=2
#lmsl=$((${normalmsl}-${rango}))
#hmsl=$((${normalmsl}+${rango}))

nminframes=50
umbral=0.1

min=201806250000
#max=201806250300
max=201806261500

cptGMT="cpt/geop500.cpt"

mins=12

OUTPUTS_DIR="/home/juan/Proyectos/pruebas/gmt/OUTPUTS/"
outputFile="${OUTPUTS_DIR}/gh500-apunt.mkv"


TMPDIR="/tmp/`basename $(type $0 | awk '{print $3}').$$`"
#TMPDIR="/tmp/animGH500.sh.16196"
mkdir -p ${TMPDIR}

errorsFile="${TMPDIR}/errors.txt"
touch ${errorsFile}



function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}


function pintarPresion+T {

#    # Pintamos isobaras de temperatura
#    color="gray55"
#    color="white"
#    gmt grdfilter ${dataFileT} -Gkk -Dp -Fb9
#    gmt grdcontour kk -V -S100 ${J} ${R} ${X} ${Y} -Q100 -C4 -W0.4,${color},-- -K -O >> ${outputFile}
#    gmt grdcontour kk -V -J -R -Q100 -A4+t"contourlabelsT.txt"   > /dev/null
#
#
#
#    awk '{print $1,$2,$4" \260C"}' contourlabelsT.txt | gmt pstext -J -R -F+f6p,Helvetica-Bold,black+a0  -Gwhite  -K -O -V >> ${outputFile}
    fecha=$1
    nframe=$2

#    ncFile="${fecha}.nc"
#    variable="t"
    dataFileT=${TMPDIR}/${fecha}_t.nc
    dataFile=${TMPDIR}/${fecha}_gh.nc


#    cdo -sellevel,500 -selvar,${variable} ${ncFile} ${dataFileT}
#    gmt grdconvert -Rd  ${dataFileT}?${variable} ${dataFileT}
##    gmt grdconvert -Rd  ${ncFile}?${variable} ${dataFileT}
#    gmt grdmath ${Rgeog} ${dataFileT} 273.15 SUB = ${dataFileT}
#
#    gmt grdproject ${dataFileT}  ${J} -G${dataFileT}


    printMessage "Calculando los mínimos locales de GH (Centro de las danas)"
    gmt grdcontour ${dataFile} ${J} ${R} -A2+t"${TMPDIR}/contourlabels.txt" -T-+a+d20p/1p+lLH -Q100 -Gn1/2c  -C2 > /dev/null
    gmt grdtrack ${TMPDIR}/contourlabels.txt -G${dataFileT} > ${TMPDIR}/kkcontourlabels.txt
    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt

    read w h < <(gmt grdinfo -C ${dataFile} | awk '{print $3,$5}')
#    read w h < <(gmt mapproject -R -J -W)


    ########### HAY QUE QUITAR EL MAPPROJECT CUANDO SE REPROYECTEN LOS GRIDS !!!!!!
    awk '{if($4=="L") printf "%s %s %.0f\n",$1,$2,$5}' ${TMPDIR}/contourlabels.txt  > ${TMPDIR}/Tlabels.txt

    read rotulowidth rotuloheight < <(convert rotulos/rotuloprecmed/rp000.png -ping -format "%w %h" info:)
    filtro="[1]setpts=0.5*PTS+${nframe}/(25*TB)[rotulo0];[0]copy[out]"
    i=0
    while read line
    do
        #echo $line
        lon=`echo ${line} | awk '{print $1}'`
        lat=`echo ${line} | awk '{print $2}'`
        t=`echo ${line} | awk '{print $3}'`
        x=`awk -v x=${lon} -v w=${w} -v rw=88 'BEGIN{printf "%d",1920*x/w - rw}'`
        y=`awk -v y=${lat} -v h=${h} -v rh=${rotuloheight} 'BEGIN{printf "%d",1080-1080*y/h - rh/2 }'`
#        if [ ${y} -lt 0 ]
#        then
#
#        fi


#        xtext=$((${x}+45))
#        ytext=$((${y}+18))

        xtext=${x}
        ytext=$((${y}+40))

        filtro="${filtro};[rotulo${i}]split[rotulo${i}][rotulo$((${i}+1))]"
#        if [ ${y} -lt 0 ]
#        then
#            filtro="${filtro};[rotulo${i}]vflip[rotulo${i}]"
#            y=`awk -v y=${lat} -v h=${h}  'BEGIN{printf "%d",1080-1080*y/h}'`
#            ytext=$((${y}+18+65))
#        fi

        convert -size 240x50 xc:none -font Roboto-Bold  -pointsize 40 -fill "white" -gravity east -annotate +0+0 "${t}°C"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 240x50+0+0 png32:${TMPDIR}/t${i}.png
        textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"

#        filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out]; [out]drawtext=fontsize=34:fontfile=Roboto-Bold.ttf:text=\'${t}°C\':x=${xtext}:y=${ytext}:enable=gt(n\,$((${nframe}+22)))[out]"
        filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out]; [out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}: enable=gt(n\,$((${nframe}+22)))[out]"
        i=$((${i}+1))

#        rename -f 's/kkd/kkc/' ${TMPDIR}/kkd-*.png

    done < <(sed '$ d' ${TMPDIR}/Tlabels.txt)

    line=`tail -n 1 ${TMPDIR}/Tlabels.txt`

    lon=`echo ${line} | awk '{print $1}'`
    lat=`echo ${line} | awk '{print $2}'`
    t=`echo ${line} | awk '{print $3}'`
    x=`awk -v x=${lon} -v w=${w} -v rw=88 'BEGIN{printf "%d",1920*x/w - rw}'`
    y=`awk -v y=${lat} -v h=${h} -v rh=${rotuloheight} 'BEGIN{printf "%d",1080-1080*y/h - rh/2 }'`


#    xtext=$((${x}+45))
#    ytext=$((${y}+18))
    xtext=${x}
    ytext=$((${y}+40))
#    if [ ${y} -lt 0 ]
#    then
#        filtro="${filtro};[rotulo${i}]vflip[rotulo${i}]"
#        y=`awk -v y=${lat} -v h=${h}  'BEGIN{printf "%d",1080-1080*y/h}'`
#        ytext=$((${y}+18+65))
#    fi


#    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out]drawtext=fontsize=34:fontfile=Roboto-Bold.ttf:text=\'${t}°C\':x=${xtext}:y=${ytext}:enable=gt(n\,$((${nframe}+22)))"
    convert -size 240x50 xc:none -font Roboto-Bold  -pointsize 40 -fill "white" -gravity east -annotate +0+0 "${t}°C"   \( +clone -background none -shadow 80x2+1+1 \) +swap -flatten -crop 240x50+0+0 png32:${TMPDIR}/t${i}.png
    textos="${textos} -f image2  -i ${TMPDIR}/t${i}.png"
    filtro="${filtro};[out][rotulo${i}]overlay= x=${x}: y=${y}[out];[out][$((${i}+2))]overlay= x=${xtext}: y=${ytext}:enable=gt(n\,$((${nframe}+22)))"

    printMessage "Insertando una animación por cada punto calculado"
    ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i rotulos/rotuloprecmed/rp%03d.png ${textos} -filter_complex "${filtro}" -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png 2>> ${errorsFile}
    rename -f 's/kkc/kkb/' ${TMPDIR}/kkc-*.png

#    ffmpeg -f image2 -i  ${TMPDIR}/kkc-%03d.png -f image2  -i rotulos/rotulop/fo%03d.png -filter_complex "[1]setpts=0.5*PTS+${nframe}/(25*TB)[rotulo];[0][rotulo]overlay= x=${x}: y=${y}[0]" -y -c:v png -f image2 ${TMPDIR}/kkd-%03d.png
#    awk '{if($4=="L") printf "%s %s %.0f\260C\n",$1,$2,$5}' contourlabels.txt |  gmt pstext -D1p/-1p -J -R -F+f19p,Helvetica-Bold,gray55 -K -O -V >> ${outputFile} #red
#    awk '{if($4=="L") printf "%s %s %.0f\260C\n",$1,$2,$5}' contourlabels.txt |  gmt pstext -J -R -F+f19p,Helvetica-Bold,white -K -O -V >> ${outputFile} #red

#ffmpeg -f image2 -i /tmp/animGH500.sh.28967/kkc-%03d.png -f image2 -i rotulos/rotulop/fo%03d.png -filter_complex \
#'[1]setpts=0.5*PTS+136/(25*TB)[rotulo0];[0]copy[out0];[rotulo0]split[rotulo0][rotulo1];[out0][rotulo0]overlay= x=1138: y=79[out1];\
#[rotulo1]split[rotulo1][rotulo2];[out1][rotulo1]overlay= x=703: y=197[out2];[rotulo2]split[rotulo2][rotulo3];\
#[out2][rotulo2]overlay= x=1765: y=431[out3];[out3][rotulo3]overlay= x=769: y=684[kk];\
#[kk]drawtext=fontsize=26:fontcolor=0x3B3B3B:fontfile=RobotoCondensed-Bold.ttf:text='\''-25°C'\'':x=775:y=710: enable=gt(n\,157)' -y -c:v png -f image2 /tmp/animGH500.sh.28967/kkd-%03d.png

#exit

}



function pintarGH500 {

    dataFile=$1

    gmt grdimage ${dataFile}  -Qg4 -E300 ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile} #-t70

    gmt grdcontour ${dataFile} -S500 -J -R  -W1p,gray25 -A+552+f8p -K -O >> ${tmpFile}


}



printMessage "Generando vídeo de ${titulo}"
printMessage "Fecha mínima: ${min}"
printMessage "Fecha máxima: ${max}"

fecha=`date -u --date="${min:0:8} ${min:8:2} -3 hours" +%Y%m%d%H%M`
fechamax=`date -u --date="${max:0:8} ${max:8:2} +6 hours" +%Y%m%d%H%M`





zmin=99999
zmax=-1
printMessage "Procesando los grids de Altura Geopotencial (GH) desde ${fecha} hasta ${fechamax}"
#Recortamos los grids a la región seleccionada y transformamos la unidades
while [ ${fecha} -le ${fechamax} ]
do
    printMessage "Procesando grid ${fecha}"
    dataFile=${TMPDIR}/${fecha}_gh.nc

    RGeog
#    echo $Rgeog

#    Rgeog=${R}

#    echo "R: ${R}"
#    echo "RGeog: ${Rgeog}"

    ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc

    cdo -sellevel,500 -selvar,gh ${TMPDIR}/${fecha}.nc ${dataFile} 2>> ${errorsFile}

    gmt grdconvert -Rd ${dataFile}\?gh ${dataFile} 2>> ${errorsFile}
    gmt grdmath ${Rgeog} ${dataFile} 9.81 DIV 10 DIV = ${dataFile} 2>> ${errorsFile}

    gmt grdproject ${dataFile} ${R} ${J} -G${dataFile} #2> ${errorsFile} ####### CUIDADOOO

    gmt grdsample  ${dataFile} -I${resolucion} -G${dataFile}




    read zminlocal zmaxlocal < <(gmt grdinfo ${dataFile} -C | awk '{printf "%d %d\n",$6,$7}')
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


printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"

./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala.png "dam" 2>> ${errorsFile}




#### Temperatura último grid
printMessage "Procesando grid de Temperatura (T) para ${max}"

ncFile="${TMPDIR}/${max}.nc"
variable="t"
dataFileT=${TMPDIR}/${max}_${variable}.nc
dataFile=${TMPDIR}/${max}_gh.nc

cdo -sellevel,500 -selvar,${variable} ${ncFile} ${dataFileT} 2>> ${errorsFile}
gmt grdconvert -Rd  ${dataFileT}?${variable} ${dataFileT} 2>> ${errorsFile}
#    gmt grdconvert -Rd  ${ncFile}?${variable} ${dataFileT}
#Rgeog=${R}
RGeog
gmt grdmath ${Rgeog} ${dataFileT} 273.15 SUB = ${dataFileT} 2>> ${errorsFile}
gmt grdproject ${dataFileT}  ${R} ${J} -G${dataFileT} 2>> ${errorsFile}




#R=`grdinfo ${dataFile} -Ir -C` ####
#
#read w h < <(gmt mapproject ${J} ${R} -W)
#h=14.0625
#J="-JX${w}c/${h}c"

JGEOG=${J}
RGEOG=${R}

read w h < <(gmt mapproject ${J} ${R} -W)
h=14.0625
J="-JX${w}c/${h}c"

R=`grdinfo ${dataFile} -Ir -C` ####



ti=${min}
nframe=0


printMessage "Generando los frames de GH desde ${min} hasta ${max} cada ${mins} minutos"
while [ ${ti} -lt ${max} ]
do


    # Sacamos los valores a-1, a0, a1 y a2 para hacer la interpolación cúbica
    tfilei=${TMPDIR}/${ti}_gh.nc

    ti_1=`date -u --date="${ti:0:8} ${ti:8:2} -3 hours" +%Y%m%d%H%M`
    tfilei_1=${TMPDIR}/${ti_1}_gh.nc

    ti1=`date -u --date="${ti:0:8} ${ti:8:2} +3 hours" +%Y%m%d%H%M`
    tfilei1=${TMPDIR}/${ti1}_gh.nc

    ti2=`date -u --date="${ti:0:8} ${ti:8:2} +6 hours" +%Y%m%d%H%M`
    tfilei2=${TMPDIR}/${ti2}_gh.nc

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
    tfile=${TMPDIR}/${fecha}_gh.nc

    tmpFile="${TMPDIR}/${fecha}-gh.ps"

    # Sacamos las dimensiones en cm para la proyección dada
#    read w h < <(gmt mapproject ${J} ${R} -W)
#    h=14.0625
#    J="-JX${w}c/${h}c"
    gmt psbasemap ${R} ${J} -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

    printMessage "Generando frame para fecha ${ti}"
    pintarGH500 ${tfile}

    gmt psbasemap -J -R -B+n -O >> ${tmpFile}
    gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

    convert -resize 1920x1080!  ${inputpng} png32:${outputpng}



    cp ${outputpng} ${TMPDIR}/fb`printf "%03d\n" ${nframe}`.png
    nframe=$((${nframe}+1))



    # Obtenemos los netcdf intermedios haciendo la interpolación cada mins minutos
#    for((i=2; i<30; i+=2))
    for((m=${mins}; m<180; m+=${mins}))
    do

#        t=`awk -v var=${i} 'BEGIN{printf "%.4f\n",var/30}'`
#        mins=`awk -v var=${i} 'BEGIN{printf "%d\n",180*var/30}'`

        # t tiene que ser entre 0 y 1
        t=`awk -v var=${m} 'BEGIN{printf "%.4f\n",var/180}'`
#        mins=`awk -v var=${i} 'BEGIN{printf "%d\n",180*var/30}'`
        fecha=`date -u --date="${ti:0:8} ${ti:8:2} +${m} minutes" +%Y%m%d%H%M`

        tfile=${TMPDIR}/${fecha}_gh.nc
        tmpFile="${TMPDIR}/${fecha}-gh.ps"

        printMessage "Interpolando grid ${fecha}"

        # interpolamos el fichero con la formula (a2*t^3 + a1*t^2 + a0*t + a-1)/2
        gmt grdmath ${A_1} ${A0} ${t} MUL ADD ${A1} ${t} 2 POW MUL ADD ${A2} ${t} 3 POW MUL ADD 2 DIV = ${tfile}


        # Sacamos las dimensiones en cm para la proyección dada
        read w h < <(gmt mapproject ${J} ${R} -W)
        gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

        printMessage "Generando frame para fecha ${fecha}"
        pintarGH500 ${tfile}

        gmt psbasemap -J -R -B+n -O >> ${tmpFile}
        gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

        inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
        outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

        convert -resize 1920x1080!  ${inputpng} png32:${outputpng}

        cp ${outputpng} ${TMPDIR}/fb`printf "%03d\n" ${nframe}`.png

        nframe=$((${nframe}+1))
    done

    ti=`date -u --date="${ti:0:8} ${ti:8:2} +3 hours" +%Y%m%d%H%M`
done



fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
tfile=${TMPDIR}/${fecha}_gh.nc

tmpFile="${TMPDIR}/${fecha}-gh.ps"

# Sacamos las dimensiones en cm para la proyección dada
read w h < <(gmt mapproject ${J} ${R} -W)
gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

printMessage "Generando frame para fecha ${fecha}"
pintarGH500 ${tfile}

gmt psbasemap -J -R -B+n -O >> ${tmpFile}
gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

convert -resize 1920x1080!  ${inputpng} png32:${outputpng}


cp ${outputpng} ${TMPDIR}/fb`printf "%03d\n" ${nframe}`.png


#
## Filtramos los máximos A y lo mínimos B quitando aquellos que aparezcan menos frames de nminframes. Esto evita que aparezcan A y B que aparecen y desaparecen rapidamente
#paste <(awk '{print $1"\t"$2"\t"$3}' ${TMPDIR}/maxmins.txt) <(awk '{print $2,$3,$4,$5}' ${TMPDIR}/maxmins.txt | gmt mapproject ${J} ${R}) > ${TMPDIR}/maxmins2.txt
#awk -v umbral=${umbral} -f filtrarpresion.awk ${TMPDIR}/maxmins2.txt > ${TMPDIR}/maxmins3.txt
#awk '{count[$8]++;}END{for(i=1;count[i]>0;i++) print i,count[i] }' ${TMPDIR}/maxmins3.txt | awk -v nframes=${nminframes} '$2>=nframes{print $1}' > ${TMPDIR}/codsfiltrados
#awk 'NR==FNR{nofiltrado[$1]=1} NR!=FNR{if(nofiltrado[$8]) print $0}'  ${TMPDIR}/codsfiltrados ${TMPDIR}/maxmins3.txt > ${TMPDIR}/maxmins4.txt
#
#
#
#fecha=${min}
#nframe=0
## Generamos las capas con los máximos y mínimos
#while [ $fecha -le ${max} ]
#do
#
##    fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
##    rotuloFecha=`LANG=ca_ES@valencia TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +%H:%MH`
##    rotuloFecha=`TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
#
#    grep ^${fecha} ${TMPDIR}/maxmins4.txt | awk '{print $2,$3,$6,$7}' > ${TMPDIR}/contourlabels.txt
#
#    basepng="${TMPDIR}/${fecha}-gh-fhd.png"
#    tmpFile="${TMPDIR}/${fecha}-gh-HL.ps"
#
#    # Sacamos las dimensiones en cm para la proyección dada
#    read w h < <(gmt mapproject ${J} ${R} -W)
#    gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}
#
#    pintarAyB
#
#    gmt psbasemap -J -R -B+n -O >> ${tmpFile}
#    gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4
#
#    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
#    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png
#
#    convert -resize 1920x1080!  ${inputpng} ${outputpng}
#
#    cp ${outputpng} ${TMPDIR}/f`printf "%03d\n" ${nframe}`.png
#
#    nframe=$((${nframe}+1))
#
#    fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
#done
#

#nframe=136


#
printMessage "Dibujando fronteras en los frames"
# Solapamos las imagenes de isobaras con el fondo de mapa de Europa
ffmpeg -f image2 -i ${TMPDIR}/fb%03d.png -f image2 -i  ${fronterasPNG}  -filter_complex 'overlay'  -y  -c:v png -f image2 ${TMPDIR}/kk%03d.png 2> ${errorsFile} #-frames 106
# Solapamos las capas con las A y las B
#ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -f image2 -i ${TMPDIR}/f%03d.png -filter_complex 'overlay'  -y -c:v png -f image2 ${TMPDIR}/kkb-%03d.png
# Repetimos el primer frame 30 veces
#ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -filter_complex 'loop=30:1:0'  -y  -c:v png -vsync 0 -f image2 ${TMPDIR}/kkb-%03d.png

##nframesloop=30
#nframesloop=15
##nframesrotulo=26
#nframesrotulo=13
printMessage "Clonando primer frame ${nframesloop} veces"
ffmpeg -f image2 -i  ${TMPDIR}/kk%03d.png -filter_complex "loop=${nframesloop}:1:0"  -y  -c:v png -vsync 0 -f image2 ${TMPDIR}/kkb-%03d.png 2>> ${errorsFile}

#pintarPresion+T ${max} $((${nframe}+30))
printMessage "Insertando animación de temperatura en el centro de las danas"
pintarPresion+T ${max} $((${nframe}+${nframesloop}))

# Insertamos la animación del rotulo
#ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i rotulos/rotulo/fo%03d.png -filter_complex 'overlay= x=25: y=15' -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png

printMessage "Insertando animación del cartel de los rótulos"
ffmpeg -f image2 -i  ${TMPDIR}/kkb-%03d.png -f image2  -i ${framescartel} -filter_complex "overlay= x=${xcartel}: y=${ycartel}" -y -c:v png -f image2 ${TMPDIR}/kkc-%03d.png 2>> ${errorsFile}

#ffmpeg -f image2 -i  ${TMPDIR}/kkc-%03d.png -f image2  -i rotulos/rotulop/fo%03d.png -filter_complex "[1]setpts=0.5*PTS+${nframe}/(25*TB)[rotulo];[0][rotulo]overlay= x=600: y=700" -y -c:v png -f image2 ${TMPDIR}/kkd-%03d.png
# Insertamos la animación del fondo del mar
#ffmpeg -i  fondos/fondomar2.mp4 -f image2 -i ${TMPDIR}/kkd-%03d.png -filter_complex '[1:v]loop=-1[kk];[0:v][kk]overlay=shortest=1'  -y ${TMPDIR}/kke-%03d.png





fecha=${min}
nframe=0
#repeat=2

# Insertamos los textos

printMessage "Generando frames con los textos de los carteles"

for((nframe=1; nframe<${nframesrotulo}; nframe++))
do
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
    convert -size 1920x1080 xc:transparent  png32:${outputpng}
done

printMessage "Generando frames con el texto para la fecha ${fecha}"
for((nframe=${nframesrotulo}; nframe<=${nframesloop}; nframe++))
do
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
#    rotuloFecha=`TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`


#    convert -font Roboto-Bold -pointsize 52 -fill "rgb(59,59,59)" -annotate +50+25 "${titulo}" -page 800x152 -gravity northwest \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto -pointsize 40 -fill "rgb(59,59,59)" -annotate +50+80 "${rotuloFecha}" -page 800x152 -gravity northwest ${outputpng} png32:${outputpng}

#    convert -font Roboto-Bold -pointsize 44 -fill "white" -annotate +112+64 "${titulo}" -page 413x64 -gravity west \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto-Bold -pointsize 32 -fill "white" -annotate +112+133 "${rotuloFecha}" -page 413x55 -gravity west ${outputpng} png32:${outputpng}

    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}


done

while [ ${fecha} -le ${max} ]
do
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframe}`.png
#    rotuloFecha=`TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`

#    convert -font Roboto-Bold -pointsize 52 -fill "rgb(59,59,59)" -annotate +50+25 "${titulo}" -page 800x152 -gravity northwest \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto -pointsize 40 -fill "rgb(59,59,59)" -annotate +50+80 "${rotuloFecha}" -page 800x152 -gravity northwest ${outputpng} png32:${outputpng}
    printMessage "Generando frame con el texto para la fecha ${fecha}"

#    convert -font Roboto-Bold -pointsize 44 -fill "white" -annotate +112+64 "${titulo}" -page 413x64 -gravity west \( -size 1920x1080 xc:transparent \) png32:${outputpng}
#    convert -font Roboto-Bold -pointsize 32 -fill "white" -annotate +112+133 "${rotuloFecha}" -page 413x55 -gravity west ${outputpng} png32:${outputpng}

    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}


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

##xscala=50
#xscala=112 #apunt
##yscala=$((560-${scaleheight}/2))
#yscala=$((620-${scaleheight}/2)) # apunt
yscala=$((${yscala}-${scaleheight}/2))

# Unimos los frames en un fichero de video e insertamos los logos

#'[2]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[0][1]overlay[out];[out][escala]overlay=x=${xscala}:y=${yscala}[out];[out]loop=20:1:151'
printMessage "Uniendo frames de textos con frames de animación y colocando la escala"
nframes=`ls -ltr ${TMPDIR}/kkc-*.png | wc -l`
ffmpeg -f image2 -i ${TMPDIR}/kkc-%03d.png -i ${TMPDIR}/rotulo-%03d.png -i  ${TMPDIR}/escala.png -filter_complex "[2]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[0][1]overlay[out];[out][escala]overlay=x=${xscala}:y=${yscala}[out];[out]loop=20:1:$((${nframes}-1))" -y -c:v png -f image2 ${TMPDIR}/kkd-%03d.png 2>> ${errorsFile}
printMessage "Generando video final con logos"


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
filtro="${filtro}[out]copy"





#ffmpeg -i ${TMPDIR}/tmp.mkv -f image2 -i logos/esw.png  -f image2 -i logos/ecmwf2.png -filter_complex '[0][1]overlay=25:1000[out];[out][2]overlay=1640:1015' -y ${outputFile}
ffmpeg -f image2 -i ${TMPDIR}/kkd-%03d.png  ${logos} -filter_complex "${filtro}" -y ${outputFile} #2>> ${errorsFile}

printMessage "Vídeo final generado"

##ffmpeg -y -nostdin -f image2 -i ${OUTPUTS_DIR}/fullhd/f%03d.png -c:v mpeg4 -qscale:v 1 presion.mp4
#ffmpeg -y -nostdin -f image2 -i ${OUTPUTS_DIR}/fullhd/f%03d.png  presion.mkv

rm -rf ${TMPDIR}