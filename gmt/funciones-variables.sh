#!/bin/bash


function cargarVariable {
    var=$1

#    index="${var}"
    funcionesprocesar=${variables[${var},fprocesar]}
    variablesprocesar=(${variables[${var},variables]})
#    function procesarGrid {
#        ${variables[${var},fprocesar]}
#    }
    function pintarVariable {
        ${variables[${var},fpintar]} $1
    }
    cptGMT=${variables[${var},cpt]}
    unidadEscala=${variables[${var},unidad]}
    esprecipitacion=${variables[${var},isprec]}
    esprecacum=${variables[${var},isprecacum]}

}


function procesarGH500 {

    cdo -sellevel,500 -selvar,gh ${TMPDIR}/${fecha}.nc ${dataFileDST} 2>> ${dataFileDST}

    gmt grdconvert -Rd ${dataFileDST}\?gh ${dataFileDST} 2>> ${errorsFile}
    gmt grdmath ${Rgeog} ${dataFileDST} 9.81 DIV 10 DIV = ${dataFileDST} 2>> ${errorsFile}

}


function pintarGH500 {

    dataFile=$1

    gmt grdimage ${dataFile}  -Qg4 -E300 ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile}

    gmt grdcontour ${dataFile} -S500 -J -R  -W1p,gray25 -A+552+f8p -K -O >> ${tmpFile}


}


function procesarT850 {
    cdo -sellevel,850 -selvar,t ${TMPDIR}/${fecha}.nc ${dataFileDST} 2>> ${errorsFile}

    gmt grdconvert -Rd ${dataFileDST}\?t ${dataFileDST} 2>> ${errorsFile}
    gmt grdmath ${Rgeog} ${dataFileDST} 273.15 SUB = ${dataFileDST} 2>> ${errorsFile}

}


function pintarT850 {
    dataFile=$1

    gmt grdimage ${dataFile}  -Qg4 -E300 ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c  -K -O >> ${tmpFile} #-t70
}



function procesarViento {
        gmt grdmath  ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT 3.6 MUL = ${dataFileDST}
        gmt grdconvert -Rd ${dataFileDST} ${dataFileDST}
        gmt grdsample ${Rgeog}  ${dataFileDST} -I${resolucion}  -G${dataFileDST}

}


function pintarViento {

    dataFile=$1
    gmt grdimage ${dataFile} ${J} ${R} ${X} ${Y} -Q -C${cptGMT} -nc+c -E192 -K -O >> ${tmpFile}
}



###### PRESIÓN #######

function pintarPresion {

    dataFile=$1
    color="white"
    disobaras=2
    detiquetas=4

    disobaras=5
    detiquetas=5

    normalmsl=1013
    rango=2
    lmsl=$((${normalmsl}-${rango}))
    hmsl=$((${normalmsl}+${rango}))


    # Pintar las isobaras de presión
#    gmt grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb19
    gmt grdfilter ${dataFile} -G${TMPDIR}/kk -Dp -Fb19 -Nr
    gmt grdcontour ${TMPDIR}/kk -Q200 -S100 ${J} ${R} -W0.5p,white -C${disobaras} -W${color} -K -O >> ${tmpFile}

#    disobaras=1
#    detiquetas=5

    # Pintar los puntos de alta presión
#    gmt grdcontour ${dataFile} -V -J -R -A8+t"contourlabels.txt" -T++a+d20p/1p+lLH -Q100 -Gn1/2c -C8 -K -O > /dev/null
#    gmt grdcontour ${TMPDIR}/kk -J -R -A${detiquetas}+t"${TMPDIR}/contourlabels.txt" -T++a+d20p/1p+lLH  -Gn1/2c -C${disobaras} -K -O > /dev/null
#    awk '{if ($4!="H" && $4!="L") print $1,$2,$4}' ${TMPDIR}/contourlabels.txt |  gmt pstext -J -R -F+f8p,Helvetica-Bold,black+a0  -G${color}  -K -O >> ${tmpFile}

    gmt grdmath ${TMPDIR}/kk DUP EXTREMA 2 EQ MUL = ${TMPDIR}/kk2
    gmt grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
    gmt grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2

#awk '{print $1,$2}' | gmt grdtrack -G${dataFile}
    gmt grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -k3 -n -r |\
     awk -v umbral=1.5 -f filtrarpresionmaxmin.awk | awk -v min=${hmsl} -v fecha=${fecha} '{press=$3/100; if (press>=min) printf "%s %s %s %d A\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt



    gmt grdmath ${TMPDIR}/kk DUP EXTREMA -2 EQ MUL = ${TMPDIR}/kk2
    gmt grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
    gmt grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2

    gmt grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -n -k3 |\
     awk -v umbral=1.5 -f filtrarpresionmaxmin.awk | awk -v max=${lmsl} -v fecha=${fecha} '{press=$3/100; if (press<=max) printf "%s %s %s %d B\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt



#
#    gmt grdtrack ${TMPDIR}/contourlabels.txt -G${dataFile} > ${TMPDIR}/kkcontourlabels.txt
#    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt
#
#    awk -v min=${hmsl} -v fecha=${fecha} '{if ($4=="H" && $5>=min) printf "%s %s %s %d A\n",fecha,$1,$2,$5}' ${TMPDIR}/contourlabels.txt >> ${TMPDIR}/maxmins.txt
#
#    # Pintar los puntos de baja presión
#    gmt grdcontour ${TMPDIR}/kk -J -R -A${detiquetas}+t"${TMPDIR}/contourlabels.txt" -T-+a+d20p/1p+lLH  -Gn1/2c  -C${disobaras} > /dev/null
#    gmt grdtrack ${TMPDIR}/contourlabels.txt -G${dataFile} > ${TMPDIR}/kkcontourlabels.txt
#    mv ${TMPDIR}/kkcontourlabels.txt ${TMPDIR}/contourlabels.txt
#
#    awk -v max=${lmsl} -v fecha=${fecha} '{if ($4=="L" && $5<=max) printf "%s %s %s %d B\n",fecha,$1,$2,$5}' ${TMPDIR}/contourlabels.txt >> ${TMPDIR}/maxmins.txt



}

# Pinta los máximos y mínimos de presión
function pintarPresionAyBGlobal {


#    awk -v min=${hmsl} '{if ($4=="A" && $3>=min) print $1,$2,"A"}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D1p/-1p  -J -R -F+f25p,Helvetica-Bold,gray -K -O -V >> ${tmpFile} #blue
#    awk -v min=${hmsl} '{if ($4=="A" && $3>=min) print $1,$2,"A"}' ${TMPDIR}/contourlabels.txt |  gmt pstext -J -R -F+f25p,Helvetica-Bold,blue -K -O -V >> ${tmpFile} #blue
#
#    awk -v min=${hmsl} '{if ($4=="A" && $3>=min) printf "%s %s %d\n",$1,$2,$3}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D1p/19p  -J -R -F+f16p,Helvetica-Bold,gray -K -O -V >> ${tmpFile} #blue
#    awk -v min=${hmsl} '{if ($4=="A" && $3>=min) printf "%s %s %d\n",$1,$2,$3}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D0p/20p -J -R -F+f16p,Helvetica-Bold,blue -K -O -V >> ${tmpFile} #blue
#
#
#    awk -v max=${lmsl} '{if ($4=="B" && $3<=max) print $1,$2,"B"}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D1p/-1p -J -R -F+f25p,Helvetica-Bold,gray -K -O -V >> ${tmpFile} #red
#    awk -v max=${lmsl} '{if ($4=="B" && $3<=max) print $1,$2,"B"}' ${TMPDIR}/contourlabels.txt |  gmt pstext -J -R -F+f25p,Helvetica-Bold,red -K -O -V >> ${tmpFile} #red
#
#    awk -v max=${lmsl} '{if ($4=="B" && $3<=max) printf "%s %s %d\n",$1,$2,$3}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D1p/19p -J -R -F+f16p,Helvetica-Bold,gray -K -O -V >> ${tmpFile} #red
#    awk -v max=${lmsl} '{if ($4=="B" && $3<=max) printf "%s %s %d\n",$1,$2,$3}' ${TMPDIR}/contourlabels.txt |  gmt pstext -D0p/20p -J -R -F+f16p,Helvetica-Bold,red -K -O -V >> ${tmpFile} #red


    dsombra=10
    xsize=110
    ysize=110

    # Calculamos la longitud de la imagen en centímetros
    read xlength ylength < <(awk -v w=${w} -v h=${h} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{print xsize/1920*w, ysize/1080*h }')
    # Calculamos la longitud de la imagen en grados lon y lat
    RTemp=`echo ${RAmp} | awk -v w=${w} -F "/" '{print $1"/"$2"/"w-$4"/"$4}'`
    read dlon dlat < <(awk -v dlon=${xlength} -v dlat=${ylength} 'BEGIN{dlon=dlon/2; dlat=dlat/2; print 12.5+dlon,12.5+dlat;}' |gmt mapproject ${RTemp} -JX${w}c/${w}c -I | gmt mapproject -Rd -JG0/0/25c -I)

    # Creamos una imagen vacia transparente de tamaño fullhd
    convert -size 1920x1080 xc:transparent ${tmpFile}
    while read line
    do
        # Calculamos las coordenadas geográficas de la letra
        read lon lat < <(echo ${line} | awk '{print $1,$2}' | gmt mapproject ${RAmp} -JX${w}c/${hsemi}c -I | gmt mapproject -Rd -JG0/0/${w}c -I)
        # Calculamos el desplazamiento en pixeles de la sombra de la letra
        read dpx dpy < <(echo ${lon} ${lat} | awk -v d=${dsombra} '{deg2rad=3.141592/180; print int(sin($1*deg2rad)*d+0.5),int(sin($2*deg2rad)*d+0.5)}')

        # Calculamos las coordenadas (x,y) donde situar la letra y los 4 puntos necesarios para hacer la transformación en perspectiva
        coordenadas=`echo ${lon} ${lat} |\
         awk -v dlon=${dlon} -v dlat=${dlat} '{\
            lon=$1;lat=$2;\
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
         gmt mapproject -Rd -JG0/0/${w}c | gmt mapproject ${RAmp} -JX${w}c/${hsemi}c  |\
         awk -v w=${w} -v h=${hsemi} 'BEGIN{ xmin=1920; ymin=1080;}{\
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
         awk -v xsize=${xsize} -v ysize=${ysize} '{printf "%s %s 0,%d,%s 0,0,%s %d,0,%s %d,%d,%s\n",$1,$2,ysize,$3,$4,xsize,$5,xsize,ysize,$6}'`

#         echo ${line}
# 	     echo ${coordenadas}
##         exit

        letra=`echo ${line} | awk '{print $4}'`
        color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`
        presion=`echo ${line} | awk '{print $3}'`

        x=`echo ${coordenadas} | awk '{print $1}'`
        y=`echo ${coordenadas} | awk '{print $2}'`
        transformacion=`echo ${coordenadas} | awk '{print $3,$4,$5,$6}'`


        #Realizamos la transformación geométrica y colocamos la letra en su posición
        convert -size ${xsize}x${ysize} xc:none -font Roboto-Bold -pointsize 75 -fill "${color}" -gravity center -annotate +0+25 "${letra}" \
         -pointsize 35 -fill "${color}" -gravity center -annotate +0-30 "${presion}" \
          -matte -virtual-pixel transparent -distort Perspective "${transformacion}"\
           \( +clone -background none -shadow 70x1-${dpx}+${dpy} \) +swap -flatten miff:- |\
         composite -geometry +${x}+$((${y}-25)) - ${tmpFile} ${tmpFile}

    done <  ${TMPDIR}/contourlabels.txt



}



# Pinta los máximos y mínimos de presión
function pintarPresionAyBNormal {

    xsize=110
    ysize=110

    # Creamos una imagen vacia transparente de tamaño fullhd
    convert -size 1920x1080 xc:transparent ${tmpFile}
    while read line
    do
        read x y < <(echo ${line} | awk -v xsize=${xsize} -v ysize=${ysize} -v w=${w} -v h=${h} '{printf "%d %d\n",$1*1920/w-xsize/2,1080-$2*1080/h-ysize/2}')

        letra=`echo ${line} | awk '{print $4}'`
        color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`
        presion=`echo ${line} | awk '{print $3}'`


        convert -size ${xsize}x${ysize} xc:none -font Roboto-Bold -pointsize 75 -fill "${color}" -gravity center -annotate +0+25 "${letra}" \
          -pointsize 35 -fill "${color}" -gravity center -annotate +0-30 "${presion}" \
           \( +clone -background none -shadow 70x1-1+1 \) +swap -flatten miff:- |\
           composite -geometry +${x}+$((${y}-25)) - ${tmpFile} ${tmpFile}

    done <  ${TMPDIR}/contourlabels.txt

}


function pintarPresionAyB {
    pintarPresionAyBNormal
}




function procesarPresion {
        gmt grdmath ${TMPDIR}/${fecha}.nc\?msl  100 DIV = ${dataFileDST}
        gmt grdconvert -Rd ${dataFileDST} ${dataFileDST}
#        gmt grdsample ${Rgeog}  ${dataFileDST}  -G{dataFileDST}
#        gmt grdcut ${Rgeog}  ${dataFileDST}  -G${dataFileDST}
        gmt grdsample ${Rgeog} -I0.5 ${dataFileDST}  -G${dataFileDST}

#        gmt grdfilter ${dataFileDST} -G${dataFileDST} -Dp -Fb19

}




######### PRECIPITACIÓN


function procesarPREC {

    variables="cp lsp"

#    dataFileDST=`dirname ${ncFile}`/`basename ${ncFile} .nc`_acumprec.nc

    for variable in ${variables}
    do
        dataFile=${TMPDIR}/${fecha}_${variable}.nc
        if [ ! -f ${dataFile} ]; then

            gmt grdconvert -Rd ${TMPDIR}/${fecha}.nc\?${variable} ${dataFile}
            gmt grdmath ${dataFile} 1000 MUL = ${dataFile}

#                # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve
#            gmt grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            gmt grdcut ${Rgeog} ${dataFile}  -G${dataFile}
        fi
        if [ ! -f ${dataFileDST} ]; then
            cp ${dataFile} ${dataFileDST}
        else
            gmt grdmath ${dataFileDST} ${dataFile} ADD = ${dataFileDST}
        fi
    done

}


function procesarTasaPREC {

    variables="crr lsrr csfr lssfr"

#    dataFileDST=`dirname ${ncFile}`/`basename ${ncFile} .nc`_acumprec.nc

    for variable in ${variables}
    do
        dataFile=${TMPDIR}/${fecha}_${variable}.nc
        if [ ! -f ${dataFile} ]; then

            gmt grdconvert -Rd ${TMPDIR}/${fecha}.nc\?${variable} ${dataFile}
            #gmt grdmath ${dataFile} 3600 MUL = ${dataFile}

            # Pasamos el grid a la resolución deseada para que pueda coger el fichero de relieve

#            gmt grdsample ${Rgeog} ${dataFile} -I${resolucion} -G${dataFile}
            gmt grdcut ${Rgeog} ${dataFile} -G${dataFile}
            gmt grdclip -Sb0/0 ${dataFile} -G${dataFile}
        fi
        if [ ! -f ${dataFileDST} ]; then
            cp ${dataFile} ${dataFileDST}
        else
            gmt grdmath ${dataFileDST} ${dataFile} ADD = ${dataFileDST}
        fi
    done

}


function pintarPREC {

    dataFile=$1


    gmt grdclip -Sb${umbralPREC}/NaN ${dataFile} -G${TMPDIR}/kk

    gmt grdimage ${TMPDIR}/kk -Qg4 -E300 -J -R -C${cptGMT} -nc+c -K -O >> ${tmpFile}

}

