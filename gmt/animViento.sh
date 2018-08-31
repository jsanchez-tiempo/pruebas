#!/bin/bash

#source cfg/spain2.cfg
#source cfg/cvalenciana2.cfg
#source cfg/europa2.cfg
source cfg/global2.cfg
source funciones.sh
source estilos/meteored2.cfg
#source estilos/apunt.cfg


#
width=`echo ${J} | sed 's/-J.*\/\(.*\)c/\1/'`
#R="-R-2.96/4.96/37.615/41.06"
max_age=50
nparticulas=$((${width}*50))
fade=7.5
#scale=200
scale=400


# Ajusta la escala a las dimensiones del mapa
# Tomamos como buena la escala de 400 en las dimensiones del mapa de España (0.00596105)
read w h < <(gmt mapproject ${J} ${R} -W)
scale=`awk -v w=${w} -v h=${h} 'BEGIN{printf "%.2f %.2f 1 1\n",w/2,h/2}' | gmt mapproject ${J} ${R} -I |\
awk -v scale=${scale} -f newlatlon.awk | awk '{print $1,$2; print $3,$4}' | gmt mapproject -J -R |\
 awk -v scale=${scale} 'NR==1{x1=$1; y1=$2}NR==2{print 0.00596105/sqrt(($1-x1)^2+($2-y1)^2)*scale}'`


nframes=20
#ncFile="2018031515.nc"

pintarIntensidad=1
pintarPresion=1

titulo="Viento en superficie"
#titulo="VENT SUPERFÍCIE"

min=201808020000
#max=201808010300
max=201808032100
# max=201808020900

mins=30


TMPDIR="/tmp"
cptGMT="cpt/v10m_201404.cpt"
#CPTFILE="cpt/windapunt.cpt"

OUTPUTS_DIR="/home/juan/Proyectos/pruebas/gmt/OUTPUTS/"
outputFile="${OUTPUTS_DIR}/viento-meteored2.mkv"
outputFile="${OUTPUTS_DIR}/vientoprueba-meteored.mkv"


# Diretorio temporal
TMPDIR=${TMPDIR}/`basename $(type $0 | awk '{print $3}').$$`
#TMPDIR=/tmp/animViento.sh.12766
mkdir -p ${TMPDIR}



function printMessage {
    echo `date +"[%Y/%m/%d %H:%M:%S]"` $1
}

function pintarViento {

    dataFile=$1

#    gmt grdimage ${dataFile}  -Qg4 -E300 ${J} ${R} ${X} ${Y} -C${cptGMT} -nc+c -K -O >> ${tmpFile} #-t70

    gmt grdimage ${dataFile} ${J} ${R} ${X} ${Y} -Q -C${cptGMT} -nc+c -E192 -K -O >> ${tmpFile}

#    gmt grdcontour ${dataFile} -S500 -J -R  -W1p,gray25 -A+552+f8p -K -O >> ${tmpFile}


}

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
     awk -v umbral=1 -f filtrarpresionmaxmin.awk | awk -v min=${hmsl} -v fecha=${fecha} '{press=$3/100; if (press>=min) printf "%s %s %s %d A\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt



    gmt grdmath ${TMPDIR}/kk DUP EXTREMA -2 EQ MUL = ${TMPDIR}/kk2
    gmt grdfilter ${TMPDIR}/kk2 -G${TMPDIR}/kk2 -Dp -Ffmconv.nc -Np
    gmt grdmath  ${TMPDIR}/kk2 0 NAN = ${TMPDIR}/kk2

    gmt grd2xyz -s ${TMPDIR}/kk2 | awk '{printf "%s %s %d\n",$1,$2,int($3*100+0.5)}' | sort -n -k3 |\
     awk -v umbral=1 -f filtrarpresionmaxmin.awk | awk -v max=${lmsl} -v fecha=${fecha} '{press=$3/100; if (press<=max) printf "%s %s %s %d B\n",fecha,$1,$2,press}' >> ${TMPDIR}/maxmins.txt



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
function pintarPresionAyB {


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


    read xlength ylength < <(awk -v w=${w} -v h=${h} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{print xsize/1920*w, ysize/1080*h }')
    RTemp=`echo ${RAmp} | awk -v w=${w} -F "/" '{print $1"/"$2"/"w-$4"/"$4}'`
    read dlon dlat < <(awk -v dlon=${xlength} -v dlat=${ylength} 'BEGIN{dlon=dlon/2; dlat=dlat/2; print 12.5+dlon,12.5+dlat;}' |gmt mapproject ${RTemp} -JX${w}c/${w}c -I | gmt mapproject -Rd -JG0/0/25c -I)

    convert -size 1920x1080 xc:transparent ${tmpFile}
    while read line
    do

        read lon lat < <(echo ${line} | awk '{print $1,$2}' | gmt mapproject ${RAmp} -JX${w}c/${hsemi}c -I | gmt mapproject -Rd -JG0/0/${w}c -I)

        read dpx dpy < <(echo ${lon} ${lat} | awk -v d=${dsombra} '{deg2rad=3.141592/180; print int(sin($1*deg2rad)*d+0.5),int(sin($2*deg2rad)*d+0.5)}')


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

         echo ${line}
	    echo ${coordenadas}
#         exit

        letra=`echo ${line} | awk '{print $4}'`
        color=`awk -v letra=${letra} 'BEGIN{print (letra=="A")?"blue":"red"}'`
        presion=`echo ${line} | awk '{print $3}'`

        x=`echo ${coordenadas} | awk '{print $1}'`
        y=`echo ${coordenadas} | awk '{print $2}'`
        transformacion=`echo ${coordenadas} | awk '{print $3,$4,$5,$6}'`



        convert -size ${xsize}x${ysize} xc:none -font Roboto-Bold -pointsize 75 -fill "${color}" -gravity center -annotate +0+25 "${letra}" \
         -pointsize 35 -fill "${color}" -gravity center -annotate +0-30 "${presion}" \
          -matte -virtual-pixel transparent -distort Perspective "${transformacion}"\
           \( +clone -background none -shadow 70x1-${dpx}+${dpy} \) +swap -flatten miff:- |\
         composite -geometry +${x}+$((${y}-25)) - ${tmpFile} ${tmpFile}

    done <  ${TMPDIR}/contourlabels.txt



}





function procesarViento {
        gmt grdmath  ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT 3.6 MUL = ${dataFileDST}
        gmt grdconvert -Rd ${dataFileDST} ${dataFileDST}
        gmt grdsample ${Rgeog}  ${dataFileDST} -I${resolucion}  -G${dataFileDST}

}

function procesarPresion {
        gmt grdmath ${TMPDIR}/${fecha}.nc\?msl  100 DIV = ${dataFileDST}
        gmt grdconvert -Rd ${dataFileDST} ${dataFileDST}
#        gmt grdsample ${Rgeog}  ${dataFileDST}  -G{dataFileDST}
#        gmt grdcut ${Rgeog}  ${dataFileDST}  -G${dataFileDST}
        gmt grdsample ${Rgeog} -I0.5 ${dataFileDST}  -G${dataFileDST}

#        gmt grdfilter ${dataFileDST} -G${dataFileDST} -Dp -Fb19

}

function procesarGrid {
        procesarViento
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


        RGeog

        dataFileDST=${TMPDIR}/${fecha}_${vardst}.nc

        for ((i=0; i<=${nargs}; i++))
        do
            dateFileSRC[${i}]=${TMPDIR}/${fecha}_varsrc[${i}].nc
        done


        ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc

        procesarGrid

        gmt grdproject ${dataFileDST} ${R} ${J} -G${dataFileDST}

        if [ ! -z ${semiglobal} ] && [  ${semiglobal} -eq 1 ]
        then
            read w h < <(gmt mapproject ${J} ${R} -W)
#            echo $w $h
            grdcut -R0/${w}/`awk -v w=${w} 'BEGIN{printf "%.4f\n",w-w*0.68}'`/${w} ${dataFileDST} -G${dataFileDST}
#            RAmp=`awk -v w=${w} 'BEGIN{a=(920/1080*w)/2; b=(920/1920*w)/2; printf "-R%.4f/%.4f/%.4f/%.4f\n",-b,w+b,-a,w+a}'`
            RAmp=`awk -v w=${w} 'BEGIN{h=w*0.68; a=1080*h/1000-h; b=(1920*w/(1000/0.68)-w)/2; printf "-R%.4f/%.4f/%.4f/%.4f\n",-b,w+b,w-w*0.68,w+a}'`
            hsemi=`awk -v h=${h} 'BEGIN{print h*0.68}'`

            echo $RAmp

            gmt grdproject -JX${w}c/${hsemi}c ${RAmp} ${dataFileDST} -G${dataFileDST}
#            gmt grdedit ${dataFileDST} -R0/${w}/`awk -v h=${h} -v hsemi=${hsemi} 'BEGIN{print h-hsemi}'`/${h}


#            grdcut -R0/${w}/`awk -v w=${w} 'BEGIN{printf "%.4f\n",w-w*0.68}'`/${w} ${dataFileDST} -G${dataFileDST}
        fi

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


function pintarVariable {
    pintarViento $1
}

#interpolarFrames "uv" ${min} ${max} ${mins} 3

function interpolarFrames {

    var=$1
#    min=$2
#    max=$3
#    mins=$4
    step=$5

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

        # Sacamos las dimensiones en cm para la proyección dada
    #    read w h < <(gmt mapproject ${J} ${R} -W)
    #    h=14.0625
    #    J="-JX${w}c/${h}c"
        gmt psbasemap ${R} ${J} -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

        printMessage "Generando frame para fecha ${ti}"

        pintarVariable ${tfile}

        gmt psbasemap -J -R -B+n -O >> ${tmpFile}
        gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

        inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
        outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

        convert -resize 1920x1080!  ${inputpng} png32:${outputpng}



        cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png
        nframe=$((${nframe}+1))



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


            # Sacamos las dimensiones en cm para la proyección dada
            read w h < <(gmt mapproject ${J} ${R} -W)
            gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

            printMessage "Generando frame para fecha ${fecha}"

            pintarVariable ${tfile}

            gmt psbasemap -J -R -B+n -O >> ${tmpFile}
            gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4 -E192

            inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
            outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

            convert -resize 1920x1080!  ${inputpng} png32:${outputpng}

            cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png

            nframe=$((${nframe}+1))
        done

        ti=`date -u --date="${ti:0:8} ${ti:8:2} +3 hours" +%Y%m%d%H%M`
    done



    fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
    tfile=${TMPDIR}/${fecha}_${var}.nc

    tmpFile="${TMPDIR}/${fecha}-${var}.ps"

    # Sacamos las dimensiones en cm para la proyección dada
    read w h < <(gmt mapproject ${J} ${R} -W)
    gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

    printMessage "Generando frame para fecha ${fecha}"

    pintarVariable ${tfile}

    gmt psbasemap -J -R -B+n -O >> ${tmpFile}
    gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4

    inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
    outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png

    convert -resize 1920x1080!  ${inputpng} png32:${outputpng}


    cp ${outputpng} ${TMPDIR}/${var}`printf "%03d\n" ${nframe}`.png



}









fecha=${min}
fechamax=${max}
#
#zmin=99999
#zmax=-1
printMessage "Procesando los grids de Viento (U y V) desde ${fecha} hasta ${fechamax}"
#Recortamos los grids a la región seleccionada y transformamos la unidades
#while [ ${fecha} -le ${fechamax} ]
#do
#    printMessage "Procesando grids ${fecha}"
#
#
#    RGeog
#
#    dataFileU=${TMPDIR}/${fecha}_u.nc
#    dataFileV=${TMPDIR}/${fecha}_v.nc
#    dataFileUV=${TMPDIR}/${fecha}_uv.nc
#
#
#    ln -sf ~/ECMWF/${fecha:0:10}.nc ${TMPDIR}/${fecha}.nc
#
#
#
#    gmt grdmath  ${TMPDIR}/${fecha}.nc\?u10 SQR ${TMPDIR}/${fecha}.nc\?v10 SQR ADD SQRT 3.6 MUL = ${dataFileUV}
#    gmt grdconvert -Rd ${dataFileUV} ${dataFileUV}
#    gmt grdsample ${Rgeog}  ${dataFileUV} -I${resolucion}  -G{dataFileUV}
#
#
#    gmt grdproject ${dataFileUV} ${R} ${J} -G${dataFileUV}
#
#    read zminlocal zmaxlocal < <(gmt grdinfo ${dataFileUV} -C | awk '{printf "%.0f %.0f\n",$6-0.5,$7+0.5}')
#    if [ ${zminlocal} -lt ${zmin} ]
#    then
#        zmin=${zminlocal}
#    fi
#    if [ ${zmaxlocal} -gt ${zmax} ]
#    then
#        zmax=${zmaxlocal}
#    fi
#
#    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
#
#done


procesarGrids "uv" ${min} ${max}
dataFileUV=${dataFileDST}

printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"

./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala.png "km/h" #2>> ${errorsFile}

if [ ${pintarPresion} -eq 1 ]
then

    function procesarGrid {
        procesarPresion
    }
    printMessage "Procesando los grids de Presión (msl) desde ${fecha} hasta ${fechamax}"

    procesarGrids "msl" ${min} ${max}

fi


#read w h < <(gmt mapproject ${J} ${R} -W)
#echo ${w} ${h}


##Frames de intensidad del viento

JGEOG=${J}
RGEOG=${R}

read w h < <(gmt mapproject ${J} ${R} -W)
h=14.0625
J="-JX${w}c/${h}c"

R=`grdinfo ${dataFileUV} -Ir -C` ####


if [ ${pintarIntensidad} -eq 1 ]
then

    interpolarFrames "uv" ${min} ${max} ${mins} 3


    nframesintermedios=$((180/${mins}))
    filtro="loop=$(( ${nframes}+${nframesloop}-1 )):1:0"

    fecha=${min}
    i=1
    while [ ${fecha} -lt ${max} ]
    do
        filtro="loop=$((${nframes}-${nframesintermedios})):1:$((${nframesintermedios}*${i}))[out];[out]${filtro}"
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        i=$((${i}+1))
    done

    filtro="[0]${filtro}[out];[out][1]overlay"

    ffmpeg -f image2 -i ${TMPDIR}/uv%03d.png -f image2 -i ${fronterasPNG} -filter_complex "${filtro}" -vsync 0 ${TMPDIR}/kk%03d.png
    rm -rf ${TMPDIR}/uv*.png
    rename -f 's/kk/uv/' ${TMPDIR}/kk*.png



fi


if [ ${pintarPresion} -eq 1 ]
then

    function pintarVariable {
        pintarPresion $1
    }

    interpolarFrames "msl" ${min} ${max} ${mins} 3




    nframesintermedios=$((180/${mins}))
    filtro="loop=$(( ${nframes}+${nframesloop}-1 )):1:0"

    fecha=${min}
    i=1
    while [ ${fecha} -lt ${max} ]
    do
        filtro="loop=$((${nframes}-${nframesintermedios})):1:$((${nframesintermedios}*${i}))[out];[out]${filtro}"
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
        i=$((${i}+1))
    done

    filtro="[0]${filtro}"

    ffmpeg -f image2 -i ${TMPDIR}/msl%03d.png -filter_complex "${filtro}" -vsync 0 ${TMPDIR}/kk%03d.png
    rm -rf ${TMPDIR}/msl*.png
    rename -f 's/kk/msl/' ${TMPDIR}/kk*.png




    nminframes=$(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(${mins}*60*2) ))
    echo ${nminframes}
#    nminframes=20

    umbral=0.1
    # Filtramos los máximos A y lo mínimos B quitando aquellos que aparezcan menos frames de nminframes. Esto evita que aparezcan A y B que aparecen y desaparecen rapidamente
    paste <(awk '{print $1"\t"$2"\t"$3}' ${TMPDIR}/maxmins.txt) <(awk '{print $2,$3,$4,$5}' ${TMPDIR}/maxmins.txt | gmt mapproject ${J} ${R}) > ${TMPDIR}/maxmins2.txt
    awk -v umbral=${umbral} -f filtrarpresion.awk ${TMPDIR}/maxmins2.txt > ${TMPDIR}/maxmins3.txt
#    awk '{count[$8]++;}END{for(i=1;count[i]>0;i++) print i,count[i] }' ${TMPDIR}/maxmins3.txt | awk -v nframes=${nminframes} '$2>=nframes{print $1}' > ${TMPDIR}/codsfiltrados
#    awk -f letrasconsecutivas.awk ${TMPDIR}/maxmins3.txt | awk -v nframes=${nminframes} '$2>=nframes{print $1}' > ${TMPDIR}/codsfiltrados
    awk -v mins=${mins} -v n=${nminframes} -f letrasconsecutivas.awk ${TMPDIR}/maxmins3.txt > ${TMPDIR}/maxmins4.txt
#    awk 'NR==FNR{nofiltrado[$1]=1} NR!=FNR{if(nofiltrado[$8]) print $0}'  ${TMPDIR}/codsfiltrados ${TMPDIR}/maxmins3.txt > ${TMPDIR}/maxmins4.txt

    filelines=`wc -l ${TMPDIR}/maxmins4.txt | awk '{print $1}'`

    fecha=${min}
    nframe=0
    # Generamos las capas con los máximos y mínimos

    if [ ${filelines} -gt 0 ]
    then
        while [ ${fecha} -le ${max} ]
        do

        #    fecha=`date -u --date="${ti:0:8} ${ti:8:2}" +%Y%m%d%H%M`
        #    rotuloFecha=`LANG=ca_ES@valencia TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +%H:%MH`
        #    rotuloFecha=`TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`

            grep ^${fecha} ${TMPDIR}/maxmins4.txt | awk '{print $2,$3,$6,$7}' > ${TMPDIR}/contourlabels.txt

#            basepng="${TMPDIR}/${fecha}-msl-fhd.png"
            tmpFile="${TMPDIR}/${fecha}-msl-HL.png"

            # Sacamos las dimensiones en cm para la proyección dada
            read w h < <(gmt mapproject ${J} ${R} -W)
#            gmt psbasemap ${R} ${J}  -B+n --PS_MEDIA="${w}cx${h}c" -Xc -Yc --MAP_FRAME_PEN="0p,black" -P -K > ${tmpFile}

            pintarPresionAyB

#            gmt psbasemap -J -R -B+n -O >> ${tmpFile}
#            gmt psconvert ${tmpFile} -P -TG -Qg1 -Qt4
#
#            inputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`.png
#            outputpng=`dirname ${tmpFile}`/`basename ${tmpFile} .ps`-fhd.png
#
#            convert -resize 1920x1080!  ${inputpng} png32:${outputpng}

            cp ${tmpFile} ${TMPDIR}/mslhl`printf "%03d\n" ${nframe}`.png

            nframe=$((${nframe}+1))

            fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
        done


        nframesintermedios=$((180/${mins}))
        filtro="loop=$(( ${nframes}+${nframesloop}-1 )):1:0"

        fecha=${min}
        i=1
        while [ ${fecha} -lt ${max} ]
        do
            filtro="loop=$((${nframes}-${nframesintermedios})):1:$((${nframesintermedios}*${i}))[out];[out]${filtro}"
            fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
            i=$((${i}+1))
        done

    #    filtro="[0]${filtro}[out];[1][out]overlay"
        filtro="[0]${filtro}"

        echo $filtro

    #    ffmpeg -loglevel debug -f image2 -i ${TMPDIR}/mslhl%03d.png -f image2 -i ${TMPDIR}/msl%03d.png -filter_complex "${filtro}"  ${TMPDIR}/kk%03d.png
        ffmpeg -f image2 -i ${TMPDIR}/mslhl%03d.png -filter_complex "${filtro}" -vsync 0 ${TMPDIR}/kk%03d.png
        rm -rf ${TMPDIR}/mslhl*.png
        rename -f 's/kk/mslhl/' ${TMPDIR}/kk*.png

        ffmpeg -f image2 -i ${TMPDIR}/msl%03d.png -f image2 -i ${TMPDIR}/mslhl%03d.png -filter_complex "overlay" ${TMPDIR}/kk%03d.png
        rm -rf ${TMPDIR}/msl*.png
        rename -f 's/kk/msl/' ${TMPDIR}/kk*.png
    fi


fi




read w h < <(gmt mapproject ${JGEOG} ${RGEOG} -W)

ymin=0

if [ ! -z ${semiglobal} ] && [  ${semiglobal} -eq 1 ]
then
    ymin=`awk -v h=${h} 'BEGIN{print h-h*0.68}'`
fi


np=${nparticulas}

#while [ ${np} -gt 0 ]
#do
    paste <(awk -v var=${w} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
          <(awk -v ymin=${ymin} -v var=${h} -v np=${np} 'BEGIN{system("shuf -n "np" -i "int(ymin*100)"-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
          <(shuf -r -n ${np} -i 1-${max_age}) | gmt mapproject ${JGEOG} ${RGEOG} -I >> ${TMPDIR}/particulas.txt
#    np=`grep "^NaN" ${TMPDIR}/particulas.txt | wc -l`
    sed '/^NaN/d' ${TMPDIR}/particulas.txt > ${TMPDIR}/kkparticulas.txt
    mv ${TMPDIR}/kkparticulas.txt ${TMPDIR}/particulas.txt

#done

#echo ${w} ${h}

#exit

#read lon lat < <(echo ${x} ${y} | gmt mapproject -J -R -I)






if [ ${pintarIntensidad} -eq 1 ]
then
    cptGMT="white"
fi


fecha=${min}
fechamax=${max}


ncFile="${TMPDIR}/${fecha}.nc"
ncFileU="${TMPDIR}/${fecha}_u.nc"
ncFileV="${TMPDIR}/${fecha}_v.nc"

gmt grdcut ${ncFile}?u10 ${Rgeog} -G${ncFileU}
gmt grdcut ${ncFile}?v10 ${Rgeog} -G${ncFileV}


awk '{print $1,$2}' ${TMPDIR}/particulas.txt | gmt grdtrack -G${ncFileU} -G${ncFileV} | awk -v scale=${scale}  -f newlatlon.awk > ${TMPDIR}/dparticulas.txt


paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | gmt mapproject -JX${w}c/${w}c ${RAmp} )\
 <(awk '{print $3,$4}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | gmt mapproject -JX${w}c/${w}c ${RAmp}) \
 <(awk -fz2color.awk <(gmt makecpt -Fr -C${cptGMT})  ${TMPDIR}/dparticulas.txt | awk '{printf "rgb(%s,%s,%s)\n",$1,$2,$3}') |\
 awk -v w=${w} -v h=${h} '{printf "stroke %s line %d,%d %d,%d\n", $5, 1920*$1/w, 1080*(h-$2)/h, 1920*$3/w, 1080*(h-$4)/h}' > ${TMPDIR}/lineas.txt

convert -size 1920x1080 xc:transparent -stroke white -strokewidth 3 -draw "@${TMPDIR}/lineas.txt" png32:${TMPDIR}/prueba.png
cp ${TMPDIR}/prueba.png ${TMPDIR}/000.png

#echo "-JX${w}c/${hsemi}c ${RAmp}"



##awk '{printf "# @P\n%s %s\n%s %s\n>-Z%s\n",$1,$2,$3,$4,$5}' dparticulas.txt \
#awk '{printf ">-Z%s\n%s %s\n%s %s\n\n",$5,$1,$2,$3,$4}' ${TMPDIR}/dparticulas.txt \
#| gmt psxy -B+n -Yc -Xc -R -J -C${cptGMT} -W1.5p,black -P --PS_MEDIA="${w}cx${h}c" > ${TMPDIR}/prueba3.ps
#gmt psconvert ${TMPDIR}/prueba3.ps -P -TG -Qg4 -Qt4
#convert ${TMPDIR}/prueba3.png -resize 1920x1080! ${TMPDIR}/000.png



#read newlon newlat < <(echo "${lon} ${lat}" | gmt grdtrack -Gtmp/totalU.nc -Gtmp/totalV.nc | awk -v scale=${scale} -f newlatlon.awk)
#echo -e "${lon} ${lat}\n${newlon} ${newlat}"| gmt psxy -B+n -Yc -Xc -R -J -W1.5p,black -P --PS_MEDIA="${w}cx${h}c"  > prueba3.ps
#gmt psconvert prueba3.ps -P -TG -Qg4 -Qt4
#mv prueba3.png frames/00.png
oldframe="${TMPDIR}/000.png"
nframe=1
nframerotulo=1
#i=1
#lon=${newlon}
#lat=${newlat}





printMessage "Generando los frames de Viento (U y V) desde ${fecha} hasta ${fechamax}"
#Recortamos los grids a la región seleccionada y transformamos la unidades
while [ ${fecha} -le ${fechamax} ]
do
    ncFile="${TMPDIR}/${fecha}.nc"
    ncFileU="${TMPDIR}/${fecha}_u.nc"
    ncFileV="${TMPDIR}/${fecha}_v.nc"

    gmt grdcut ${ncFile}?u10 ${Rgeog} -G${ncFileU}
    gmt grdcut ${ncFile}?v10 ${Rgeog} -G${ncFileV}

    nframesfecha=${nframes}
    if [ ${fecha} -eq ${min} ]
    then
        nframesfecha=$((${nframes}+${nframesloop}-1))
    fi

    printMessage "Generando ${nframesfecha} frames para fecha ${fecha}"

    for ((i=0; i<${nframesfecha}; i++, nframe++))
    do
        printMessage "Generando frame ${i} para fecha ${fecha}"

#        time convert  ${oldframe} -matte -channel a -evaluate subtract ${fade}% ${TMPDIR}/baseframe.png

        start_time="$(date -u +%s.%N)"

        awk '$3>0' ${TMPDIR}/particulas.txt > ${TMPDIR}/kkparticulas
        n=`wc -l ${TMPDIR}/kkparticulas | awk '{print $1}'`



        if [ ${n} -lt ${nparticulas} ]
        then
            np=$((${nparticulas}-${n}))
#            while [ ${np} -gt 0 ]
#            do
                paste <(awk -v var=${w} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
                  <(awk -v ymin=${ymin} -v var=${h} -v np=${np} 'BEGIN{system("shuf -n "np" -i "int(ymin*100)"-"int(var*100))}' | awk '{printf "%.2f 50\n",$1/100}') \
                  | gmt mapproject ${RGEOG} ${JGEOG} -I >> ${TMPDIR}/kkparticulas
#                  np=`grep "^NaN" ${TMPDIR}/kkparticulas | wc -l`
                  sed '/^NaN/d' ${TMPDIR}/kkparticulas > ${TMPDIR}/kkparticulas2
                  mv ${TMPDIR}/kkparticulas2 ${TMPDIR}/kkparticulas
#            done
            mv ${TMPDIR}/kkparticulas ${TMPDIR}/particulas.txt
        fi



        awk '{print $1,$2}' ${TMPDIR}/particulas.txt | gmt grdtrack  -G${ncFileU} -G${ncFileV} | awk -v scale=${scale}  -f newlatlon.awk > ${TMPDIR}/dparticulas.txt



#        paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} ) <(awk '{print $3,$4,$5}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG}) |\
#         awk -v w=${w} -v h=${h} '{printf "line %d,%d %d,%d\n", 1920*$1/w, 1080*(h-$2)/h, 1920*$3/w, 1080*(h-$4)/h}' > ${TMPDIR}/lineas.txt

         paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | gmt mapproject -JX${w}c/${w}c ${RAmp})\
        <(awk '{print $3,$4}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | gmt mapproject -JX${w}c/${w}c ${RAmp}) \
        <(awk -fz2color.awk <(gmt makecpt -Fr -C${cptGMT}) ${TMPDIR}/dparticulas.txt | awk '{printf "rgb(%s,%s,%s)\n",$1,$2,$3}') |\
        awk -v w=${w} -v h=${h} '{printf "stroke %s line %d,%d %d,%d\n", $5, 1920*$1/w, 1080*(h-$2)/h, 1920*$3/w, 1080*(h-$4)/h}' > ${TMPDIR}/lineas.txt


#        time convert -size 1920x1080 xc:transparent -stroke white -strokewidth 3 -draw "@${TMPDIR}/lineas.txt" png32:${TMPDIR}/prueba3.png
#        cp ${TMPDIR}/prueba.png ${TMPDIR}/000.png




#    #    awk '{printf "# @P\n%s %s\n%s %s\n>-Z%s\n",$1,$2,$3,$4,$5}' dparticulas.txt \
#        awk '{printf ">-Z%s\n%s %s\n%s %s\n\n",$5,$1,$2,$3,$4}' ${TMPDIR}/dparticulas.txt \
#        | gmt psxy -B+n -Yc -Xc -R -J -C${cptGMT} -W1.5p,black -P --PS_MEDIA="${w}cx${h}c" > ${TMPDIR}/prueba3.ps


        paste ${TMPDIR}/particulas.txt ${TMPDIR}/dparticulas.txt | awk '{print $6,$7,$3-1}' > ${TMPDIR}/kkparticulas
        mv ${TMPDIR}/kkparticulas ${TMPDIR}/particulas.txt



#        time gmt psconvert ${TMPDIR}/prueba3.ps  -P -TG -Qg4 -Qt4
#        time convert \( ${oldframe} -matte -channel a -evaluate subtract ${fade}% \) \( ${TMPDIR}/prueba3.png -resize 1920x1080! \) -composite png32:${TMPDIR}/prueba3.png

         convert \( ${oldframe} -matte -channel a -evaluate subtract ${fade}% \)\
          \( -size 1920x1080 xc:transparent -stroke white -strokewidth 3 -draw "@${TMPDIR}/lineas.txt" \)\
           -composite png32:${TMPDIR}/prueba3.png
#        echo $?
        if [ $? -ne 0 ]
        then
            echo saliendo
            exit
        fi

#        time composite ${TMPDIR}/prueba3.png ${TMPDIR}/baseframe.png ${TMPDIR}/prueba3.png
#        convert -resize 1920x1080!  prueba3.png prueba3.png
    #    composite prueba3.png europaapunt.png  prueba3.png


        mv ${TMPDIR}/prueba3.png ${TMPDIR}/`printf "%03d" ${nframe}`.png
        oldframe="${TMPDIR}/`printf "%03d" ${nframe}`.png"

        end_time="$(date -u +%s.%N)"
        echo "Tiempo frame: $(bc <<<"$end_time-$start_time")"



    done


    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframerotulo}`.png

    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
    printMessage "Generando frame con el texto para la fecha ${fecha}"

    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}


    nframerotulo=$((nframerotulo+1))

    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
done

#fecha=`basename ${ncFile} .nc`
#rotuloFecha=`LANG=ca_ES@valencia TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +%H:%MH`
#
#
##composite ${file} cvapunt.png  ${file}
#file=${TMPDIR}/transparent.png
#convert -size 1920x1080 xc:none ${file}
##composite -geometry +2+45 rotulo.png ${file} ${file}
##convert -font Helvetica-Bold -pointsize 30 -fill black -annotate +2+45 "${rotuloFecha}" -page 150x60 -gravity east ${file} ${file}
#composite -geometry +50+990 logoecmwf.png ${file} ${file}
##    composite -geometry +50+160 escala.png ${file} ${file}
#
#scaleheight=`convert ${TMPDIR}/escala.png -ping -format "%h" info:`
#composite -geometry +50+$((540-${scaleheight}/2)) ${TMPDIR}/escala.png ${file} ${file}

#for ((i=0; i<${nframes}; i++))
#do
#    file="${TMPDIR}/`printf "%02d" ${i}`.png"
#
#    convert -resize 1920x1080! ${file} ${file}
#    composite ${file} cvapunt.png  ${file}
#    composite ${TMPDIR}/transparent.png ${file} ${file}
##    composite -geometry +2+45 rotulo.png ${file} ${file}
##    convert -font Helvetica-Bold -pointsize 30 -fill black -annotate +2+45 "${rotuloFecha}" -page 150x60 -gravity east ${file} ${file}
##    composite -geometry +20+990 logoecmwf.png ${file} ${file}
###    composite -geometry +50+160 escala.png ${file} ${file}
##    composite -geometry +50+$((540-${scaleheight}/2)) escala.png ${file} ${file}
#
#done



#cd frames
#ffmpeg -y -nostdin -f image2 -i "${dir}/%02d.png" -c:v mpeg4 particula.mp4
#ffmpeg -y -nostdin -f image2 -i ${TMPDIR}/%03d.png -c:v mpeg4 -qscale:v 1 particula.mp4


scaleheight=`convert ${TMPDIR}/escala.png -ping -format "%h" info:`
if [ ${scaleheight} -ge 790 ]
then
    convert ${TMPDIR}/escala.png -resize 85x800\> ${TMPDIR}/escala.png
    scaleheight=790
fi

yscala=$((${yscala}-${scaleheight}/2))



#Ponemos los rotulos

opciones=" -f image2 -i ${TMPDIR}/rotulo-001.png"
finicial=${nframesrotulo}
ffinal=$(( ${nframes}+${nframesloop}-1 ))


#Fondo del mar
filtro="[$((${nframerotulo}+${nlogos}+3))]loop=-1[mar];[mar][0]overlay[base];[1]fade=in:$((${nframesloop}-15)):15[viento];"
#filtro="[1]fade=in:$((${nframesloop}-15)):15[viento];[0][viento]overlay[out];"


if [ ! -z ${semiglobal} ] && [  ${semiglobal} -eq 1 ]
then
    tmpSombraPNG=${TMPDIR}/sombra.png
    read w h < <(convert ${filesombra} -format "%w %h" info:)
    h=`awk -v h=${h} 'BEGIN{printf "%d",h*0.68}'`
    convert ${filesombra} -crop ${w}x${h}+0+0 ${tmpSombraPNG}
    filesombra=${tmpSombraPNG}
    pos="south"
    hpx=1002
    convert \( -size 1920x1080 xc:transparent \) \( ${filesombra} -resize 1920x${hpx}\> \) -gravity ${pos} -composite -flatten png32:${tmpSombraPNG}
    filtro="${filtro}[base]setsar=sar=1,format=rgba[base];[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarPresion}+4))]setsar=sar=1,format=rgba[sombra];[base][sombra]blend=all_mode=multiply:all_opacity=1,format=yuva422p10le[base];"
    frameSombra=" -f image2 -i ${tmpSombraPNG}"
fi


framesUV=""
if [ ${pintarIntensidad} -eq 1 ]
then
#    filtro="[1]fade=in:$((${nframesloop}-15)):15[viento];[$((${nframerotulo}+${nlogos}+4))]fade=in:$((${nframesloop}-15)):15[uv];[0][uv]overlay[out];[out][viento]overlay[out];"
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+4))]fade=in:$((${nframesloop}-15)):15[uv];[base][uv]overlay[base];"
    framesUV="-f image2 -i ${TMPDIR}/uv%03d.png"
fi

filtro="${filtro}[base][viento]overlay=shortest=1[out];"



if [ ${pintarPresion} -eq 1 ]
then
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+4))]fade=in:$((${nframesloop}-15)):15[press];[out][press]overlay[out];"
    framesPress="-f image2 -i ${TMPDIR}/msl%03d.png"
fi


filtro="${filtro}[2]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[out][escala]overlay=x=${xscala}:y=${yscala}[out];\
[out][3]overlay=x=${xcartel}:y=${ycartel}[out];[out][4]overlay=enable=between(n\,${finicial}\,${ffinal})"


#"[$((${nframerotulo}+${nlogos}+4))]fade=in:0:10[uv]"



for((i=2; i<${nframerotulo}; i++))
do
    opciones="${opciones} -f image2 -i ${TMPDIR}/rotulo-`printf "%03d" ${i}`.png"
    finicial=$(( (${i}-1)*${nframes}+${nframesloop} ))
    ffinal=$(( ${i}*${nframes}+${nframesloop}-1 ))

    filtro="${filtro}[out];[out][$((${i}+3))]overlay=enable=between(n\,${finicial}\,${ffinal})"
done

#Ponemos los logos

logos=""
#filtro=""
if [ ${nlogos} -gt 0 ]
then
    logos="-f image2 -i ${logo[0]} "
    filtro="${filtro}[out];[out][$((${nframerotulo}+3))]overlay=${xlogo[0]}:${ylogo[0]}"
fi

for((nlogo=1; nlogo<${nlogos}; nlogo++))
do
    logos="${logos} -f image2 -i ${logo[${nlogo}]} "
    filtro="${filtro};[out][$((${nframerotulo}+${nlogo}+3))]overlay=${xlogo[${nlogo}]}:${ylogo[${nlogo}]}"
done


##Fondo del mar
#filtro="${filtro}[out];[$((${nframerotulo}+${nlogos}+3))]loop=-1[mar];[mar][out]overlay=shortest=1"







#fondoPNG="${TMPDIR}/kk%03d.png"


echo $filtro

ffmpeg -y -f image2 -i ${fondoPNG} -f image2 -i ${TMPDIR}/%03d.png -f image2 -i  ${TMPDIR}/escala.png -f image2 -i  ${framescartel} ${opciones} ${logos} -i ${fondomar} ${framesUV} ${framesPress} ${frameSombra} -filter_complex ${filtro}  ${outputFile}
#rm -rf ${dir}