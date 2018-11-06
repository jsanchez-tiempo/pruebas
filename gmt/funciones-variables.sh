#!/bin/bash


function cargarVariable {
    var=$1


    funcionesprocesar=${variables[${var},fprocesar]}
    variablesprocesar=(${variables[${var},variables]})
    maxalcancevariables=(${variables[${var},maxalcance]})
    if [ ${#maxalcancevariables[*]} -eq 0 ]
    then
        i=0
        for funcion in "${funcionesprocesar}" #((i=0;i<${#variablesprocesar[*]};i++))
        do
            maxalcancevariables[$i]=9999
            i=$(( $i+1 ))
        done
    fi

    function pintarVariable {
        ${variables[${var},fpintar]} $1
    }
    cptGMT=${variables[${var},cpt]}
    unidadEscala=${variables[${var},unidad]}
    esprecipitacion=${variables[${var},isprec]}
    esprecacum=${variables[${var},isprecacum]}
    estransparente=${variables[${var},istransparent]}

}


function procesarGH500 {

    ${CDO} -sellevel,500 -selvar,gh ${TMPDIR}/${fecha}.nc ${dataFileDST} 2>> ${dataFileDST}



    ${GMT} grdconvert -Rd ${dataFileDST}\?gh ${dataFileDST} 2>> ${errorsFile}
    ${GMT} grdmath ${Rgeog} ${dataFileDST} 9.81 DIV 10 DIV = ${dataFileDST} 2>> ${errorsFile}

#    ${GMT} grdsample -I0.5 ${dataFileDST}  -G${dataFileDST}

}


function pintarGH500 {

    dataFile=$1

    ${GMT} grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb9 -Nr

    [ ! -z ${dpi} ] && E="-E${dpi}"
    ${GMT} grdimage ${TMPDIR}/kk  -Qg4 ${E} ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile}

##    gmt grdcontour ${dataFile} -S500 -J -R  -W1p,gray25 -A+552+f8p -K -O >> ${tmpFile}
#    ${GMT} grdcontour ${TMPDIR}/kk  -S500 ${J} ${R} -W1p,gray25 -C+552 -K -O >> ${tmpFile}


}

function procesarT500 {
    ${CDO} -sellevel,500 -selvar,t ${TMPDIR}/${fecha}.nc ${dataFileDST} 2>> ${errorsFile}

    ${GMT} grdconvert -Rd ${dataFileDST}\?t ${dataFileDST} 2>> ${errorsFile}
    ${GMT} grdmath ${Rgeog} ${dataFileDST} 273.15 SUB = ${dataFileDST} 2>> ${errorsFile}

}

function procesarT850 {
    ${CDO} -sellevel,850 -selvar,t ${TMPDIR}/${fecha}.nc ${dataFileDST} 2>> ${errorsFile}

    ${GMT} grdconvert -Rd ${dataFileDST}\?t ${dataFileDST} 2>> ${errorsFile}
    ${GMT} grdmath ${Rgeog} ${dataFileDST} 273.15 SUB = ${dataFileDST} 2>> ${errorsFile}


}


function pintarT850 {
    dataFile=$1

    [ ! -z ${dpi} ] && E="-E${dpi}"
    ${GMT} grdimage ${dataFile}  -Qg4 ${E} ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile} #-t70
}

function pintarT500 {
    dataFile=$1

    [ ! -z ${dpi} ] && E="-E${dpi}"
    ${GMT} grdimage ${dataFile}  -Qg4 ${E} ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile} #-t70
}




function procesarViento {
        ${GMT} grdmath  ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT 3.6 MUL = ${dataFileDST}
        ${GMT} grdconvert -Rd ${dataFileDST} ${dataFileDST}
        ${GMT} grdsample ${Rgeog}  ${dataFileDST} -I${resolucion}  -G${dataFileDST}

}

function procesarViento300 {

        dataFileU=${TMPDIR}/${fecha}_u300.nc
        dataFileV=${TMPDIR}/${fecha}_v300.nc
        ${CDO} -sellevel,300 -selvar,u ${TMPDIR}/${fecha}.nc ${dataFileU} 2>> ${errorsFile}
        ${CDO} -sellevel,300 -selvar,v ${TMPDIR}/${fecha}.nc ${dataFileV} 2>> ${errorsFile}

        ${GMT} grdmath   ${dataFileU}\?u SQR  ${dataFileV}\?v SQR ADD SQRT 3.6 MUL = ${dataFileDST}
        ${GMT} grdconvert -Rd ${dataFileDST} ${dataFileDST}
        ${GMT} grdsample ${Rgeog}  ${dataFileDST} -I${resolucion}  -G${dataFileDST}

}

function procesarRachasViento {
        fechasig=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        ${GMT} grdmath  ${TMPDIR}/${fechasig}.nc\?fg310 3.6 MUL = ${dataFileDST}
        ${GMT} grdconvert -Rd ${dataFileDST} ${dataFileDST}
        ${GMT} grdcut ${Rgeog}  ${dataFileDST} -G${dataFileDST}

}



function pintarViento {

    dataFile=$1
    ${GMT} grdimage ${dataFile} ${J} ${R} ${X} ${Y} -Q -C${cptGMT} -nc+c -E${dpi} -K -O >> ${tmpFile}

}

function pintarViento300 {

    dataFile=$1
    ${GMT} grdimage ${dataFile} ${J} ${R} ${X} ${Y} -Q -C${cptGMT} -nc+c -E${dpi} -K -O >> ${tmpFile}

}



###### PRESIÓN #######

function pintarPresion {

    dataFile=$1
#    color="white"
#        color="gray35"
#    disobaras=2
#    detiquetas=4






    # Pintar las isobaras de presión
#    ${GMT} grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb19
    ${GMT} grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb${pressmooth} -Nr

#    echo ${colorisobaras}
#    colorisobaras="white"
    ${GMT} grdcontour ${TMPDIR}/kk -Q200 -S100 ${J} ${R} -W1p,white -C${disobaras} -W${colorisobaras} -K -O >> ${tmpFile}

#    disobaras=1
#    detiquetas=5

    # Pintar los puntos de alta presión
#    gmt grdcontour ${dataFile} -V -J -R -A8+t"contourlabels.txt" -T++a+d20p/1p+lLH -Q100 -Gn1/2c -C8 -K -O > /dev/null
#    gmt grdcontour ${TMPDIR}/kk -J -R -A${detiquetas}+t"${TMPDIR}/contourlabels.txt" -T++a+d20p/1p+lLH  -Gn1/2c -C${disobaras} -K -O > /dev/null
#    awk '{if ($4!="H" && $4!="L") print $1,$2,$4}' ${TMPDIR}/contourlabels.txt |  gmt pstext -J -R -F+f8p,Helvetica-Bold,black+a0  -G${color}  -K -O >> ${tmpFile}

    if [ -z ${calcularMaxMinPress} ] || [ ${calcularMaxMinPress} -eq 1 ]
    then
        ${GMT} grdmath ${TMPDIR}/kk DUP EXTREMA 2 EQ MUL = ${TMPDIR}/kk2
        ${GMT} grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
        ${GMT} grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2


        ${GMT} grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -k3 -n -r |\
         awk -v umbral=${dminletras} -f awk/filtrarpresionmaxmin.awk | awk -v min=${hmsl} -v fecha=${fecha} '{press=$3/100; if (press>=min) printf "%s %s %s %d A\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt
    #    echo ${dminletras}
        ${GMT} grdmath ${TMPDIR}/kk DUP EXTREMA -2 EQ MUL = ${TMPDIR}/kk2
        ${GMT} grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
        ${GMT} grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2

        ${GMT} grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -n -k3 |\
         awk -v umbral=${dminletras} -f awk/filtrarpresionmaxmin.awk | awk -v max=${lmsl} -v fecha=${fecha} '{press=$3/100; if (press<=max) printf "%s %s %s %d B\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt
    fi
}


function generarMaxMinPresion {

    dataFile=$1

    # Pintar las isobaras de presión
#    ${GMT} grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb19
    ${GMT} grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb${pressmooth} -Nr


    ${GMT} grdmath ${TMPDIR}/kk DUP EXTREMA 2 EQ MUL = ${TMPDIR}/kk2
    ${GMT} grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
    ${GMT} grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2


    ${GMT} grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -k3 -n -r |\
     awk -v umbral=${dminletras} -f awk/filtrarpresionmaxmin.awk | awk -v min=${hmsl} -v fecha=${fecha} '{press=$3/100; if (press>=min) printf "%s %s %s %d A\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt
#     echo ${dminletras}
    ${GMT} grdmath ${TMPDIR}/kk DUP EXTREMA -2 EQ MUL = ${TMPDIR}/kk2
    ${GMT} grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
    ${GMT} grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2

    ${GMT} grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -n -k3 |\
     awk -v umbral=${dminletras} -f awk/filtrarpresionmaxmin.awk | awk -v max=${lmsl} -v fecha=${fecha} '{press=$3/100; if (press<=max) printf "%s %s %s %d B\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt

}


# Pinta los máximos y mínimos de presión en un mapa global
function pintarPresionAyBGlobal {

    w=`echo ${JGEOG} | sed -n 's/\-JG.*\/\(.*\)c/\1/p'`


    # Sacamos una R nueva para que el centro de la proyección caiga en el centro de esa R (mapas semiglobales o desplazados)
    RTemp=`echo ${RAMP} | sed 's/-R//' | awk -F "/" -v w=${w} \
     '{left=-$1; right=$2-w; bottom=-$3; top=$4-w;\
      if(left>right)\
        right=left;\
      else \
        left=right;\
      if(bottom>top)\
        top=bottom;\
      else\
        bottom=top;\
      printf "-R%.4f/%.4f/%.4f/%.4f\n",-left,w+right,-bottom,w+top}'`
#    echo $RAMP
#    echo $RTemp


    local ylengthtemp=`echo ${RTemp} | sed 's/-R//' | awk -F "/" '{printf "%.4f",$4-$3}'`
    local xlengthtemp=`echo ${RTemp} | sed 's/-R//' | awk -F "/" '{printf "%.4f",$2-$1}'`

    # Calculamos la longitud de la imagen en centímetros
    # xsizeicono/xsize*xlength
    read xlengthicono ylengthicono < <(awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} \
     -v w=${w} -v ylength=${ylength} -v xsizeicono=${xsizeicono} -v ysizeicono=${ysizeicono} \
     -v xlengthnuevo=${xlengthtemp} -v ylengthnuevo=${ylengthtemp} \
     'BEGIN{mul=w/xlength; print xsizeicono/xsize*w*mul*xlength/xlengthnuevo, ysizeicono/ysize*ylength*mul^2*xsize/ysize*ylength/ylengthnuevo}')

#     echo ${xlengthicono} ${ylengthicono}


    read dlon dlat < <(awk -v dlon=${xlengthicono} -v dlat=${ylengthicono} -v w=${w} 'BEGIN{dlon=dlon/2; dlat=dlat/2; print w/2+dlon,w/2+dlat;}'\
     | ${GMT} mapproject ${RTemp} -JX${w}c/${w}c -I | ${GMT} mapproject -Rd -JG0/0/${w} -I)


#    echo ${dlat} ${dlon}
#    nicono=0
    # Creamos una imagen vacia transparente de tamaño fullhd
    ${CONVERT} -size ${xsize}x${ysize} xc:transparent png32:${tmpFile}
    while read line
    do
        # Calculamos las coordenadas geográficas de la letra
        read lon lat < <(echo ${line} | awk '{print $1,$2}' | ${GMT} mapproject ${RAMP} -JX${xlength}c/${ylength}c -I | ${GMT} mapproject -Rd -JG0/0/${w}c -I)
        # Calculamos el desplazamiento en pixeles de la sombra de la letra
        read dpx dpy < <(echo ${lon} ${lat} | awk -v d=${dsombraicono} '{deg2rad=3.141592/180; print int(sin($1*deg2rad)*d+0.5),int(sin($2*deg2rad)*d+0.5)}')

        # Calculamos las coordenadas (x,y) donde situar la letra y los 4 puntos necesarios para hacer la transformación en perspectiva
        coordenadas=`echo ${lon} ${lat} |\
         awk -v dlon=${dlon} -v dlat=${dlat} '{\
            lon=($1<0?$1+360:$1);lat=$2;\
            latmin=lat-dlat;\
            if(latmin<-90)\
                latmin=-180-latmin;\
            latmax=lat+dlat;\
            if(latmax>90)\
                latmax=180-latmax;\
            print lon-dlon,latmin;\
            print lon-dlon,latmax;\
            print lon+dlon,latmax;\
            print lon+dlon,latmin}' |\
         ${GMT} mapproject -Rd -JG0/0/${w}c | ${GMT} mapproject ${RAMP}  -JX${xlength}c/${ylength}c  |\
         awk -v w=${xlength} -v h=${ylength} 'BEGIN{ xmin=1920; ymin=1080;}{\
                punto[NR-1]["x"]=$1*1920/w;\
                punto[NR-1]["y"]=1080-$2*1080/h;\
                if(punto[NR-1]["x"]<xmin)\
                    xmin=punto[NR-1]["x"];\
                if(punto[NR-1]["y"]<ymin)\
                    ymin=punto[NR-1]["y"]}\
              END{printf "%d %d ",xmin,ymin;\
                for(i=0;i<4;i++)\
                    printf "%d,%d ",punto[i]["x"]-xmin,punto[i]["y"]-ymin;\
                printf "\n";}'  |\
         awk -v xsize=${xsizeicono} -v ysize=${ysizeicono} '{printf "%s %s 0,%d,%s 0,0,%s %d,0,%s %d,%d,%s\n",$1,$2,ysize,$3,$4,xsize,$5,xsize,ysize,$6}'`

#         echo ${line}
# 	     echo ${coordenadas}
##         exit

        local fade=`echo ${line} | awk '{print $5}'`
        local letra=`echo ${line} | awk '{print $4}'`
        local color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`
#        local color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"rgb(0,255,255)":"rgb(247,62,56)"}'`
        local presion=`echo ${line} | awk '{print $3}'`

        local x=`echo ${coordenadas} | awk '{print $1}'`
        local y=`echo ${coordenadas} | awk '{print $2}'`
        local transformacion=`echo ${coordenadas} | awk '{print $3,$4,$5,$6}'`

        read xsizetemp ysizetemp < <(echo ${transformacion} | tr " " "\n" | awk -F "," -v xsize=${xsizeicono} -v ysize=${ysizeicono} \
        '{xsize=($3>xsize)?$3:xsize; ysize=($4>ysize)?$4:ysize;} END {print xsize,ysize}')
#        echo ${xsizetemp} ${ysizetemp}

        #Realizamos la transformación geométrica y colocamos la letra en su posición
        ${CONVERT} -size ${xsizetemp}x${ysizetemp} xc:none -font Roboto-Bold -pointsize 75 -fill "${color}" -gravity center -annotate +0+25 "${letra}" \
         -pointsize 35 -fill "${color}" -gravity center -annotate +0-30 "${presion}" \
          -matte -virtual-pixel transparent -mattecolor none -distort Perspective "${transformacion}"\
           \( +clone -background none -shadow 70x1-${dpx}+${dpy} \) +swap -flatten -channel a -evaluate multiply ${fade} miff:- |\
         ${COMPOSITE} -geometry +${x}+$((${y})) - ${tmpFile} png32:${tmpFile}

#        echo $nicono
#         cp ${tmpFile} ${TMPDIR}/${nicono}.png
#         nicono=$(($nicono + 1))

    done <  ${TMPDIR}/contourlabels.txt



}


# Pinta las etiquetas
function pintarEtiquetasGlobal {

    w=`echo ${JGEOG} | sed -n 's/\-JG.*\/\(.*\)c/\1/p'`


    # Sacamos una R nueva para que el centro de la proyección caiga en el centro de esa R (mapas semiglobales o desplazados)
    RTemp=`echo ${RAMP} | sed 's/-R//' | awk -F "/" -v w=${w} \
     '{left=-$1; right=$2-w; bottom=-$3; top=$4-w;\
      if(left>right)\
        right=left;\
      else \
        left=right;\
      if(bottom>top)\
        top=bottom;\
      else\
        bottom=top;\
      printf "-R%.4f/%.4f/%.4f/%.4f\n",-left,w+right,-bottom,w+top}'`


    local ylengthtemp=`echo ${RTemp} | sed 's/-R//' | awk -F "/" '{printf "%.4f",$4-$3}'`
    local xlengthtemp=`echo ${RTemp} | sed 's/-R//' | awk -F "/" '{printf "%.4f",$2-$1}'`


    # Creamos una imagen vacia transparente de tamaño fullhd
    ${CONVERT} -size ${xsize}x${ysize} xc:transparent png32:${tmpFile}


    while read line
    do
        local xsizelabel=`echo ${line} | awk  -F ";" '{print $11}'`
        local ysizelabel=`echo ${line} | awk  -F ";" '{print $12}'`

        # Calculamos la longitud de la imagen en centímetros
        read xlengthicono ylengthicono < <(awk -v xsize=${xsize} -v ysize=${ysize} -v xlength=${xlength} \
         -v w=${w} -v ylength=${ylength} -v xsizeicono=${xsizelabel} -v ysizeicono=${ysizelabel} \
         -v xlengthnuevo=${xlengthtemp} -v ylengthnuevo=${ylengthtemp} \
         'BEGIN{mul=w/xlength; print xsizeicono/xsize*w*mul*xlength/xlengthnuevo, ysizeicono/ysize*ylength*mul^2*xsize/ysize*ylength/ylengthnuevo}')

        read dlon dlat < <(awk -v dlon=${xlengthicono} -v dlat=${ylengthicono} -v w=${w} 'BEGIN{dlon=dlon/2; dlat=dlat/2; print w/2+dlon,w/2+dlat;}'\
         | ${GMT} mapproject ${RTemp} -JX${w}c/${w}c -I | ${GMT} mapproject -Rd -JG0/0/${w} -I)


        # Calculamos las coordenadas geográficas de la letra
        read lon lat < <(echo ${line} | awk -F ";" '{print $2,$3}' | ${GMT} mapproject ${RAMP} -JX${xlength}c/${ylength}c -I | ${GMT} mapproject -Rd -JG0/0/${w}c -I)
        # Calculamos el desplazamiento en pixeles de la sombra de la letra
        read dpx dpy < <(echo ${lon} ${lat} | awk -v d=${dsombraicono} '{deg2rad=3.141592/180; print int(sin($1*deg2rad)*d+0.5),int(sin($2*deg2rad)*d+0.5)}')

        # Calculamos las coordenadas (x,y) donde situar la letra y los 4 puntos necesarios para hacer la transformación en perspectiva
        coordenadas=`echo ${lon} ${lat} |\
         awk -v dlon=${dlon} -v dlat=${dlat} '{\
            lon=($1<0?$1+360:$1);lat=$2;\
            latmin=lat-dlat;\
            if(latmin<-90)\
                latmin=-180-latmin;\
            latmax=lat+dlat;\
            if(latmax>90)\
                latmax=180-latmax;\
            print lon-dlon,latmin;\
            print lon-dlon,latmax;\
            print lon+dlon,latmax;\
            print lon+dlon,latmin}' |\
         ${GMT} mapproject -Rd -JG0/0/${w}c | ${GMT} mapproject ${RAMP}  -JX${xlength}c/${ylength}c  |\
         awk -v w=${xlength} -v h=${ylength} 'BEGIN{ xmin=1920; ymin=1080;}{\
                punto[NR-1]["x"]=$1*1920/w;\
                punto[NR-1]["y"]=1080-$2*1080/h;\
                if(punto[NR-1]["x"]<xmin)\
                    xmin=punto[NR-1]["x"];\
                if(punto[NR-1]["y"]<ymin)\
                    ymin=punto[NR-1]["y"]}\
              END{printf "%d %d ",xmin,ymin;\
                for(i=0;i<4;i++)\
                    printf "%d,%d ",punto[i]["x"]-xmin,punto[i]["y"]-ymin;\
                printf "\n";}'  |\
         awk -v xsize=${xsizelabel} -v ysize=${ysizelabel} '{printf "%s %s 0,%d,%s 0,0,%s %d,0,%s %d,%d,%s\n",$1,$2,ysize,$3,$4,xsize,$5,xsize,ysize,$6}'`



#        #Calculamos la posición donde colocar el icono
#        read x y < <(echo ${line} | awk -F ";" -v xsizeicono=${xsizelabel} -v ysizeicono=${ysizelabel} \
#         -v w=${xlength} -v h=${ylength} -v xsize=${xsize} -v ysize=${ysize} \
#          '{printf "%d %d\n",$2*xsize/w-xsizeicono/2,ysize-$3*ysize/h-ysizeicono/2}')

        local label=`echo ${line} | awk -F ";" '{print $4}'`
        local fontsize=`echo ${line} | awk -F ";" '{print $5}'`
        local color=`echo ${line} | awk -F ";" '{print $6}'`
        local bgcolor=`echo ${line} | awk -F ";" '{print $7}'`
        local fade=`echo ${line} | awk  -F ";" '{print $8}'`
        local dx=`echo ${line} | awk  -F ";" '{print $9}'`
        local dy=`echo ${line} | awk  -F ";" '{print $10}'`

        local x=`echo ${coordenadas} | awk '{print $1}'`
        local y=`echo ${coordenadas} | awk '{print $2}'`
        local transformacion=`echo ${coordenadas} | awk '{print $3,$4,$5,$6}'`

        read xsizetemp ysizetemp < <(echo ${transformacion} | tr " " "\n" | awk -F "," -v xsize=${xsizelabel} -v ysize=${ysizelabel} \
        '{xsize=($3>xsize)?$3:xsize; ysize=($4>ysize)?$4:ysize;} END {print xsize,ysize}')



#        #Colocamos el icono dentro de la imagen principal
#        ${CONVERT} -size ${xsizelabel}x${ysizelabel} xc:${bgcolor} -font Roboto-Bold \
#          -pointsize ${fontsize} -fill "${color}" -gravity center -annotate +0+0 "${label}" \
#           \( +clone -background none -shadow 70x1-1+1 \) +swap -flatten -channel a -evaluate multiply ${fade} miff:- |\
#           ${COMPOSITE} -geometry +$((${x}+${dx}))+$((${y}+${dy})) - ${tmpFile} png32:${tmpFile}

                #Realizamos la transformación geométrica y colocamos la letra en su posición
        ${CONVERT} -size ${xsizetemp}x${ysizetemp} xc:${bgcolor} -font Roboto-Bold \
        -pointsize ${fontsize} -fill "${color}" -gravity center -annotate +0+0 "${label}" \
          -matte -virtual-pixel transparent -mattecolor none -distort Perspective "${transformacion}"\
           \( +clone -background none -shadow 70x1-${dpx}+${dpy} \) +swap -flatten -channel a -evaluate multiply ${fade} miff:- |\
         ${COMPOSITE} -geometry +$((${x}+${dx}))+$((${y}+${dy})) - ${tmpFile} png32:${tmpFile}

    done <  ${TMPDIR}/etiquetas.txt

}


# Pinta los máximos y mínimos de presión
function pintarPresionAyBNormal {


    # Creamos una imagen vacia transparente de tamaño fullhd
    ${CONVERT} -size ${xsize}x${ysize} xc:transparent png32:${tmpFile}
    while read line
    do
        #Calculamos la posición donde colocar el icono
        read x y < <(echo ${line} | awk -v xsizeicono=${xsizeicono} -v ysizeicono=${ysizeicono} \
         -v w=${xlength} -v h=${ylength} -v xsize=${xsize} -v ysize=${ysize} \
          '{printf "%d %d\n",$1*xsize/w-xsizeicono/2,ysize-$2*ysize/h-ysizeicono/2}')

        local letra=`echo ${line} | awk '{print $4}'`
        local color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`
        local presion=`echo ${line} | awk '{print $3}'`
        local fade=`echo ${line} | awk '{print $5}'`

        #Colocamos el icono dentro de la imagen principal
        ${CONVERT} -size ${xsizeicono}x${ysizeicono} xc:none -font Roboto-Bold \
          -pointsize 75 -fill "${color}" -gravity center -annotate +0+25 "${letra}" \
          -pointsize 35 -fill "${color}" -gravity center -annotate +0-30 "${presion}" \
           \( +clone -background none -shadow 70x1-1+1 \) +swap -flatten -channel a -evaluate multiply ${fade} miff:- |\
           ${COMPOSITE} -geometry +${x}+$((${y})) - ${tmpFile} png32:${tmpFile}

    done <  ${TMPDIR}/contourlabels.txt

}


function pintarPresionAyB {
    pintarPresionAyBNormal
}


# Pinta las etiquetas
function pintarEtiquetasNormal {

#    xsizelabel=150
#    ysizelabel=50


    # Creamos una imagen vacia transparente de tamaño fullhd
    ${CONVERT} -size ${xsize}x${ysize} xc:transparent png32:${tmpFile}
    while read line
    do
        local xsizelabel=`echo ${line} | awk  -F ";" '{print $11}'`
        local ysizelabel=`echo ${line} | awk  -F ";" '{print $12}'`
        #Calculamos la posición donde colocar el icono
        read x y < <(echo ${line} | awk -F ";" -v xsizeicono=${xsizelabel} -v ysizeicono=${ysizelabel} \
         -v w=${xlength} -v h=${ylength} -v xsize=${xsize} -v ysize=${ysize} \
          '{printf "%d %d\n",$2*xsize/w-xsizeicono/2,ysize-$3*ysize/h-ysizeicono/2}')

        local label=`echo ${line} | awk -F ";" '{print $4}'`
        local fontsize=`echo ${line} | awk -F ";" '{print $5}'`
        local color=`echo ${line} | awk -F ";" '{print $6}'`
        local bgcolor=`echo ${line} | awk -F ";" '{print $7}'`
        local fade=`echo ${line} | awk  -F ";" '{print $8}'`
        local dx=`echo ${line} | awk  -F ";" '{print $9}'`
        local dy=`echo ${line} | awk  -F ";" '{print $10}'`


        #Colocamos el icono dentro de la imagen principal
        ${CONVERT} -size ${xsizelabel}x${ysizelabel} xc:${bgcolor} -font Roboto-Bold \
          -pointsize ${fontsize} -fill "${color}" -gravity center -annotate +0+0 "${label}" \
           \( +clone -background none -shadow 70x1-1+1 \) +swap -flatten -channel a -evaluate multiply ${fade} miff:- |\
           ${COMPOSITE} -geometry +$((${x}+${dx}))+$((${y}+${dy})) - ${tmpFile} png32:${tmpFile}

    done <  ${TMPDIR}/etiquetas.txt

}





function pintarEtiquetas {
    pintarEtiquetasNormal
}




function procesarPresion {
        ${GMT} grdmath ${TMPDIR}/${fecha}.nc\?msl 100 DIV = ${dataFileDST}
        ${GMT} grdconvert -Rd ${dataFileDST} ${dataFileDST}
        ${GMT} grdsample ${Rgeog} -I${presres} ${dataFileDST}  -G${dataFileDST}
}



function procesarNubes {

    ${GMT} grdconvert -Rd ${TMPDIR}/${fecha}.nc\?tcc ${dataFileDST} 2>> ${errorsFile}
    ${GMT} grdcut ${Rgeog} ${dataFileDST}  -G${dataFileDST} 2>> ${errorsFile}

}

function pintarNubes {

    dataFile=$1
    [ ! -z ${dpi} ] && E="-E${dpi}"
    ${GMT} grdimage ${dataFile} ${J} ${R} ${X} ${Y} -Q -C${cptGMT} -nc+c ${E} -K -O >> ${tmpFile}

}

######### PRECIPITACIÓN

function procesarPREC {

#    variables="cp lsp"

    variables=$1
#    echo ${variables}
#    dataFileDST=`dirname ${ncFile}`/`basename ${ncFile} .nc`_acumprec.nc

    for variable in ${variables}
    do
        dataFile=${TMPDIR}/${fecha}_${variable}.nc
        if [ ! -f ${dataFile} ]; then

            ${GMT} grdconvert -Rd ${TMPDIR}/${fecha}.nc\?${variable} ${dataFile}
            ${GMT} grdmath ${dataFile} 1000 MUL = ${dataFile}

            # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve
#           ${GMT} grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            ${GMT} grdcut ${Rgeog} ${dataFile}  -G${dataFile}
        fi
        if [ ! -f ${dataFileDST} ]; then
            cp ${dataFile} ${dataFileDST}
        else
            ${GMT} grdmath ${dataFileDST} ${dataFile} ADD = ${dataFileDST}
        fi
    done

    if [ ${dataFileDST} == ${dataFileMin} ]
    then
        dataFileMin=${TMPDIR}/min${vardst}.nc
        cp ${dataFileDST} ${dataFileMin}
    fi
    ${GMT} grdmath ${dataFileDST} ${dataFileMin} SUB = ${dataFileDST}



}


function procesarTasaPREC {


#    variables="crr lsrr csfr lssfr"
    variables=$1
#    echo ${variables}
#    dataFileDST=`dirname ${ncFile}`/`basename ${ncFile} .nc`_acumprec.nc

    for variable in ${variables}
    do
        dataFile=${TMPDIR}/${fecha}_${variable}.nc
        if [ ! -f ${dataFile} ]; then

            ${GMT} grdconvert -Rd ${TMPDIR}/${fecha}.nc\?${variable} ${dataFile}
            #${GMT} grdmath ${dataFile} 3600 MUL = ${dataFile}

            # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve

#            ${GMT} grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            ${GMT} grdcut ${Rgeog} ${dataFile} -G${dataFile}
            ${GMT} grdclip -Sb0/0 ${dataFile} -G${dataFile}
        fi
        if [ ! -f ${dataFileDST} ]; then
            cp ${dataFile} ${dataFileDST}
        else
            ${GMT} grdmath ${dataFileDST} ${dataFile} ADD = ${dataFileDST}
        fi
    done

}

function procesarNieve {
    variables="sf"
    procesarPREC "${variables}"
}

function procesarTasaNieve {
    variables="csfr lssfr"
    procesarTasaPREC "${variables}"
}

function procesarLluvia {
    variables="cp lsp"
    procesarPREC "${variables}"
}

function procesarTasaLluvia {
    variables="crr lsrr csfr lssfr"
    procesarTasaPREC "${variables}"
}

function pintarPREC {

    dataFile=$1

    ${GMT} makecpt -C${cptGMT} -Fr | awk -v umbral=${umbralPREC} '$1>=umbral{print $0}' > ${TMPDIR}/kk.cpt

    tcolor=`sed -n '/^B/p' ${TMPDIR}/kk.cpt | tr "/" "," | awk '{printf "rgb(%s)",$2}'`


    [ ! -z ${dpi} ] && E="-E${dpi}"
    ${GMT} grdimage ${dataFile} -Qg4 ${E} ${J} ${R} -C${TMPDIR}/kk.cpt -nc+c -K -O >> ${tmpFile}

}

