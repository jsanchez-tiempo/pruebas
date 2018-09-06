#!/bin/bash


GLOBEDIR="GLOBE_DATA"
GLOBEFILESOURCE="${GLOBEDIR}/abcdefghijklmnop.grd"
CPTGLOBE="cpt/GMTglobe.cpt"
cm2inch=0.393701
xsize=1920
ysize=1080
xlength=25
ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`
dpi=`awk -v cm2inch=${cm2inch} -v xlength=${xlength} -v xsize=${xsize} 'BEGIN{printf "%d\n",xsize/(xlength*cm2inch)}'`


lon=-4.7
lat=40.4

#lon=0
#lat=0

xdesinicial=0
ydesinicial=-275  # semiglobal: -195 para que se vea el hemisferio norte y -80 para darle margen

xdes=`awk -v xdes=${xdesinicial} -v xlength=${xlength} -v xsize=${xsize} 'BEGIN{printf "%.4f\n",xlength*xdes/xsize}'`
ydes=`awk -v ydes=${ydesinicial} -v ylength=${ylength} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",ylength*ydes/ysize}'`


J="-JG${lon}/${lat}/${xlength}c"
zoom=10


dlat=`gmt grdinfo ${GLOBEFILESOURCE} -C | awk '{print $9}'`
#resolucion=`awk -v grados=${dlat} -v z=${zoom} 'BEGIN{z=int(z); secs=int(3600*grados*z+0.5); if(secs%60==0)print secs/60"m"; else print secs"s";}'`
resolucion=`awk -v grados=${dlat} -v z=${zoom} 'BEGIN{z=int(z); print int(3600*grados*z+0.5); }'`
resformat=`awk -v secs=${resolucion} 'BEGIN{if(secs%60==0)print secs/60"m"; else print secs"s";}'`

newlat=`awk -v lat=${lat} -v dlat=${dlat} 'BEGIN{printf "%.4f\n",lat+dlat}'`
xlengthamp=`echo "${lon} ${newlat}" | gmt mapproject ${J} -Rd |\
 awk -v zoom=${zoom} -v w=${xlength} -v h=${ylength} -v ysize=${ysize} \
 'function abs(v) {return v < 0 ? -v : v} {print abs(w*h/(zoom*ysize*(w*0.5 - $2)))}'`


# xlengthamp=11.9792 #Global actual
xlengthamp=19.1482 #Semiglobal actual
echo ${xlengthamp}

JAMP="-JG${lon}/${lat}/${xlengthamp}c"

read lonmin latmin < <(awk -v w=${xlength} -v h=${ylength} -v wamp=${xlengthamp} 'BEGIN{x=y=wamp/2; printf "%.4f %.4f\n",x-w/2,y-h/2}' | gmt mapproject -Rd ${JAMP} -I)
read lonmax latmax < <(awk -v w=${xlength} -v h=${ylength} -v wamp=${xlengthamp} 'BEGIN{x=y=wamp/2; printf "%.4f %.4f\n",x+w/2,y+h/2}' | gmt mapproject -Rd ${JAMP} -I)

GLOBEFILE="${GLOBEDIR}/globe${resformat}.grd"
if [ ! -f ${GLOBEFILE} ]
then
    echo buscando  ${resolucion}
    rescercana=`ls -1 ${GLOBEDIR} |  sed -n '/globe.*.grd/p' | sed 's/globe\(.*\).grd/\1/;s/s//;s/m/\*60/' | bc \
     | sort -n | awk -v res=${resolucion} 'NR==1{anterior=$1}{if($1>res){print anterior; noend=1; exit;}anterior=$1}END{if(noend==0)print $1}' \
     | awk '{secs=$1; if(secs%60==0)print secs/60"m"; else print secs"s";}'`
    GLOBEFILE="${GLOBEDIR}/globe${rescercana}.grd"
    echo ${rescercana}
#    ls -1 ${GLOBEDIR}/globe${resformat}.grd  | sed 's/globe\(.*\).grd/\1/;s/s//;s/m/\*60/' | bc | sort -n | awk -v res=650 '{if($1>=res){print $1; exit;}}END{print $1}'
#    gmt grdsample  ${GLOBEFILESOURCE} -I${resolucion} -G${GLOBEFILE}
fi


R="-R${lonmin}/${latmin}/${lonmax}/${latmax}+r"


#if (( $(echo "${xlength} > ${xlengthamp}" | bc -l) )) || [ ${lonmin} == "NaN" ] || [ ${latmin} == "NaN" ] || [ ${lonmax} == "NaN" ] || [ ${latmax} == "NaN" ]
if [ ${lonmin} == "NaN" ] || [ ${latmin} == "NaN" ] || [ ${lonmax} == "NaN" ] || [ ${latmax} == "NaN" ]
then

    R="-Rd"
    J=${JAMP}
#    ylengthamp=`awk -v xlength=${xlengthamp} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`
#    echo ${ylengthamp}
#    xdes=`awk -v xdes=${xdesinicial} -v xlength=${xlengthamp} -v xsize=${xsize} 'BEGIN{printf "%.4f\n",xlength*xdes/xsize}'`
#    ydes=`awk -v ydes=${ydesinicial} -v ylength=${ylengthamp} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",ylength*ydes/ysize}'`
#    echo ${ydes}
fi



echo ${R}

#gmt grdimage ${GLOBEFILE} -Bp1g1 -C${CPTGLOBE} -E${dpi} ${JAMP} -Rd -Xc -Yc --PS_MEDIA=${xlength}cx${ylength}c -P -n+c > prueba.ps
gmt grdimage ${GLOBEFILE}   -C${CPTGLOBE} -E${dpi} ${J} ${R} -Xc${xdes}c -Yc${ydes}c --PS_MEDIA=${xlength}cx${ylength}c -P -n+c   > prueba2.ps
#gmt psconvert prueba.ps -E${dpi} -P -TG -Qg1 -Qt4
gmt psconvert prueba2.ps -E${dpi} -P -TG -Qg1 -Qt4
