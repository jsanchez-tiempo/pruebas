#!/bin/bash






#source cfg/spain2.cfg
#source cfg/cvalenciana2.cfg
#source cfg/europa2.cfg
#source cfg/global2.cfg
source defaults.cfg
source cfg/mapa3.cfg
#source cfg/semiglobalpacifico.cfg
source funciones.sh
source funciones-variables.sh
source variables.sh
source estilos/meteored2.cfg
#source estilos/apunt.cfg

ylength=`awk -v xlength=${xlength} -v xsize=${xsize} -v ysize=${ysize} 'BEGIN{printf "%.4f\n",xlength*ysize/xsize}'`

#
width=`echo ${J} | sed 's/-J.*\/\(.*\)c/\1/'`
#R="-R-2.96/4.96/37.615/41.06"
max_age=50
#nparticulas=$((${width}*50))
nparticulas=`awk -v w=${width} -v n=50 'BEGIN{printf "%d",w*n}'`
fade=7.5
#scale=200
scale=400


# Ajusta la escala a las dimensiones del mapa
# Tomamos como buena la escala de 400 en las dimensiones del mapa de España (0.00596105)
read w h < <(gmt mapproject ${J} ${R} -W)
scale=`awk -v w=${w} -v h=${h} 'BEGIN{printf "%.2f %.2f 1 1\n",w/2,h/2}' | gmt mapproject ${J} ${R} -I |\
awk -v scale=${scale} -f newlatlon.awk | awk '{print $1,$2; print $3,$4}' | gmt mapproject -J -R |\
 awk -v scale=${scale} 'NR==1{x1=$1; y1=$2}NR==2{print 0.00596105/sqrt(($1-x1)^2+($2-y1)^2)*scale}'`


pintarViento=1
pintarIntensidad=1
pintarPresion=0

escalaViento=1

#titulo="Viento en superficie"
titulo="Prec, nieve y presión"
#titulo="VENT SUPERFÍCIE"


fechapasada=201803150000

min=201803150100
#max=201808010300
#max=201809052100
max=201803160000
max=201803150300
#max=201808310300

## Si es precipitación prevista y corresponde al dato de un paso de tiempo (múltiplo de 3)
#if [ ${esprecipitacion} -eq 1 ] && [ ${esprecacum} -eq 0 ] && [ $(( $(echo ${min:8:2}| awk '{print int($0)}')%3 )) -eq 0 ]
#then
#    min=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
#fi

minreal=${min}
min=${minreal:0:8}`printf "%02d" $(( $(echo ${min:8:2}|awk '{print int($0)}')/3*3 ))`00
desfasemin=$((${minreal:0:10}-${min:0:10}))


#fronterasPNG=${fronterasPNGw}


mins=30
#mins=60
# Número de horas en las que cambia el viento
stepviento=3
# Número de horas en las que cambian los rotulos
steprotulo=1

slowmotion=2
#slowmotion=10
nframes=20
nframes=1
#ncFile="2018031515.nc"
nframesinicio=${nframes}

if [ ${nframesinicio} -lt $((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins})) ]
then
    nframesinicio=$((${slowmotion}*180/${mins}-${desfasemin}*${slowmotion}*60/${mins}))
fi

if [ ${nframes} -lt $((${slowmotion}*180/${mins})) ]
then
    nframes=$((${slowmotion}*180/${mins}))
fi

echo ${nframes} ${nframesinicio}



umbralPREC=0.5
TMPDIR="/tmp"

#cptGMT="cpt/v10m_201404.cpt"
#cptGMT="cpt/geop500.cpt"
#CPTFILE="cpt/windapunt.cpt"

OUTPUTS_DIR="/home/juan/Proyectos/pruebas/gmt/OUTPUTS/"
outputFile="${OUTPUTS_DIR}/viento-meteored2.mkv"
outputFile="${OUTPUTS_DIR}/vientopruebaescalas-meteored.mkv"


# Diretorio temporal
TMPDIR=${TMPDIR}/`basename $(type $0 | awk '{print $3}').$$`
#TMPDIR=/tmp/animViento.sh.12766
mkdir -p ${TMPDIR}



errorsFile="${TMPDIR}/errors.txt"
touch ${errorsFile}


########## COMIENZO

#if [ ${pintarPresion} -eq 1 ]
#then
#
#    function procesarGrid {
#        procesarPresion
#    }
#    printMessage "Procesando los grids de Presión (msl) desde ${fecha} hasta ${fechamax}"
#
#    procesarGrids "msl" ${min} ${max}
#
#fi


JGEOG=${J}
RGEOG=${R}

variablesanimacion=("nubes" "prec" "nieve")
nombresvariables=("Nubes" "Lluvia" "Nieve")

indexescala=(1 2)
opcionesEntrada=""

if [ ${pintarIntensidad} -eq 1 ]
then

    filtro="[0][1]overlay"
    ivar=0
    for variablefondo in ${variablesanimacion[*]}
    do

        J=${JGEOG}
        R=${RGEOG}
        cargarVariable ${variablefondo}

        fecha=${min}
        fechamax=${max}
        #
        #zmin=99999
        #zmax=-1
        printMessage "Procesando los grids de Viento (U y V) desde ${fecha} hasta ${fechamax}"

        variable=${variablefondo}
        nvar=0
        #echo ${variablesprocesar[*]}
        for funcion in ${funcionesprocesar}
        do
            echo ${nvar}
            if [ ${#variablesprocesar[*]} -gt 0 ]
            then
                 variable=${variablesprocesar[${nvar}]}
                 nvar=$((${nvar}+1))
            fi

            echo ${#variablesprocesar[*]} ${variable}
            function procesarGrid {
                ${funcion}
            }
            procesarGrids ${variable} ${min} ${max}
        done



        dataFileUV=${dataFileDST}


        ##Frames de intensidad del viento

        JGEOG=${J}
        RGEOG=${R}

        #read w h < <(gmt mapproject ${J} ${R} -W)
        ##h=14.0625
        ##J="-JX${w}c/${h}c"
        J="-JX${xlength}c/${ylength}c"
        R=`grdinfo ${dataFileUV} -Ir -C` ####


    #if [ ${pintarIntensidad} -eq 1 ]
    #then

        stepinterp=3
    #    minimo=${min}
        if [ ${esprecipitacion} -eq 1 ]
        then

            interpolarPREC ${variablefondo} ${min} ${max}
            stepinterp=1

    #        if [ ${esprecacum} -eq 0 ] ##################
    #        then
    ###            minimo=`date -u --date="${min:0:8} ${min:8:2} +1 hours" +%Y%m%d%H%M`
    ##            cp ${TMPDIR}/${variablefondo}002.png ${TMPDIR}/${variablefondo}001.png
    ##            cp ${TMPDIR}/${variablefondo}002.png ${TMPDIR}/${variablefondo}000.png
    #        fi
        fi

        interpolarFrames "${variablefondo}" ${min} ${max} ${mins} ${stepinterp}
        if [ ${estransparente} -eq 1 ]
        then
            black2transparentFrames "${variablefondo}"
        fi
        replicarFrames "${variablefondo}"

        opcionesEntrada="${opcionesEntrada} -f image2 -i ${TMPDIR}/${variablefondo}%03d.png"
        if [ ${ivar} -gt 0 ]
        then
            filtro="${filtro}[out];[out][$((${ivar}+1))]overlay"
        fi

        ivar=$((${ivar}+1))

    done

    i=0
    for ivar in ${indexescala[*]}
    do
        variablefondo=${variablesanimacion[${ivar}]}
        cargarVariable ${variablefondo}
        calcularMinMax "${variablefondo}" ${min} ${max} ${stepinterp}
        printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"
        P=""
        if [ ${tipoescala[${i}]} == "h" ]
        then
            P="-p"
        fi
        ./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala${ivar}.png  ${unidadEscala} ${nombresvariables[${ivar}]} #2>> ${errorsFile}

        i=$((${i}+1))

    done

    echo ${opcionesEntrada}
    echo ${filtro}

    variablefondo=`echo ${variablesanimacion[*]} | tr " " "-"`
    ffmpeg ${opcionesEntrada} -f image2 -i ${fronterasPNG} -filter_complex ${filtro} -vsync 0 ${TMPDIR}/kk%03d.png
    rename -f "s/kk/${variablefondo}/" ${TMPDIR}/kk*.png
fi



if [ ${pintarPresion} -eq 1 ]
then

    J=${JGEOG}
    R=${RGEOG}

    function procesarGrid {
        procesarPresion
    }
    printMessage "Procesando los grids de Presión (msl) desde ${fecha} hasta ${fechamax}"

    procesarGrids "msl" ${min} ${max}


    J="-JX${xlength}c/${ylength}c"
    R=`grdinfo ${dataFileDST} -Ir -C` ####
    #Redifinimos la función pintarVariable
    function pintarVariable {
        pintarPresion $1
    }

    interpolarFrames "msl" ${min} ${max} ${mins} 3
    replicarFrames "msl"



    nminframes=$(( (`date -u -d "${max:0:8} ${max:8:4}" +%s`-`date -u -d "${min:0:8} ${min:8:4}" +%s`)/(${mins}*60*2) ))
    echo ${nminframes}
#    nminframes=20

    printMessage "Calculando máximos/mínimos de MSL desde ${min} hasta ${max}"
    umbral=0.2
    # Filtramos los máximos A y lo mínimos B quitando aquellos que aparezcan menos frames de nminframes. Esto evita que aparezcan A y B que aparecen y desaparecen rapidamente
    paste <(awk '{print $1"\t"$2"\t"$3}' ${TMPDIR}/maxmins.txt) <(awk '{print $2,$3,$4,$5}' ${TMPDIR}/maxmins.txt | gmt mapproject ${J} ${R}) > ${TMPDIR}/maxmins2.txt
    awk -v umbral=${umbral} -f filtrarpresion.awk ${TMPDIR}/maxmins2.txt > ${TMPDIR}/maxmins3.txt
    awk -v mins=${mins} -v n=${nminframes} -f letrasconsecutivas.awk ${TMPDIR}/maxmins3.txt | sort -k1,1 |\
     awk -v N=5 -v nf=4  -v maxfecha=${max} -v minfecha=${minreal} -f suavizarletras.awk> ${TMPDIR}/maxmins4.txt

    filelines=`wc -l ${TMPDIR}/maxmins4.txt | awk '{print $1}'`

    fecha=${min}
    nframe=0

    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        function pintarPresionAyB {
            pintarPresionAyBGlobal
        }
    fi

    printMessage "Generando los frames de máximos/mínimos de MSL desde ${min} hasta ${max} cada ${mins} minutos"

#    filelines=0
    # Generamos las capas con los máximos y mínimos
    if [ ${filelines} -gt 0 ]
    then
        while [ ${fecha} -le ${max} ]
        do

            grep ^${fecha} ${TMPDIR}/maxmins4.txt | awk '{print $2,$3,$6,$7,$9}' > ${TMPDIR}/contourlabels.txt

            tmpFile="${TMPDIR}/${fecha}-msl-HL.png"

            # Sacamos las dimensiones en cm para la proyección dada
#            read w h < <(gmt mapproject ${J} ${R} -W)
#            echo $w $h

            if [ ${fecha} -ge ${minreal} ]
            then
                printMessage "Generando frame para fecha ${fecha}"
                pintarPresionAyB


                cp ${tmpFile} ${TMPDIR}/mslhl`printf "%03d\n" ${nframe}`.png

                nframe=$((${nframe}+1))
            fi


            fecha=`date -u --date="${fecha:0:8} ${fecha:8:4} +${mins} minutes" +%Y%m%d%H%M`
        done

#exit
        replicarFrames "mslhl"

        ffmpeg -f image2 -i ${TMPDIR}/msl%03d.png -f image2 -i ${TMPDIR}/mslhl%03d.png -filter_complex "overlay" ${TMPDIR}/kk%03d.png
        rm -rf ${TMPDIR}/msl*.png
        rename -f 's/kk/msl/' ${TMPDIR}/kk*.png
    fi


fi


if [ ${pintarViento} -eq 1 ]
then

    zmin=9999
    zmax=-9999
    read w h < <(gmt mapproject ${JGEOG} ${RGEOG} -W)

    ymin=0

    np=${nparticulas}


    paste <(awk -v var=${w} -v np=${np} 'BEGIN{system("shuf -n "np" -i 0-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
          <(awk -v ymin=${ymin} -v var=${h} -v np=${np} 'BEGIN{system("shuf -n "np" -i "int(ymin*100)"-"int(var*100))}' | awk '{printf "%.2f\n",$1/100}') \
          <(shuf -r -n ${np} -i 1-${max_age}) | gmt mapproject ${JGEOG} ${RGEOG} -I >> ${TMPDIR}/particulas.txt
    sed '/^NaN/d' ${TMPDIR}/particulas.txt > ${TMPDIR}/kkparticulas.txt
    mv ${TMPDIR}/kkparticulas.txt ${TMPDIR}/particulas.txt




    if [ ${pintarIntensidad} -eq 1 ]
    then
        cptGMT="white"
    fi
    cptGMT="cpt/v10m_201404.cpt"



    fecha=${min}
    fechamax=${max}


    ncFile="${TMPDIR}/${fecha}.nc"
    ncFileU="${TMPDIR}/${fecha}_u.nc"
    ncFileV="${TMPDIR}/${fecha}_v.nc"

    gmt grdcut ${ncFile}?u10 ${Rgeog} -G${ncFileU}
    gmt grdcut ${ncFile}?v10 ${Rgeog} -G${ncFileV}


    awk '{print $1,$2}' ${TMPDIR}/particulas.txt | gmt grdtrack -G${ncFileU} -G${ncFileV} | awk -v scale=${scale}  -f newlatlon.awk > ${TMPDIR}/dparticulas.txt

    comando="cat"
    if [ ! -z ${global} ] && [  ${global} -eq 1 ]
    then
        comando="gmt mapproject -JX${w}c/${w}c ${RAMP}"
    #    comando="gmt mapproject ${J} ${RAMP}"
    fi

    read zminlocal zmaxlocal < <(awk 'BEGIN{min=9999; max=-9999}$5<min{min=$5}$5>max{max=$5}END{print min" "max}' ${TMPDIR}/dparticulas.txt)
    if (( `echo "${zminlocal} <  ${zmin}" | bc -l` ))
    then
        zmin=${zminlocal}
    fi
    if (( `echo "${zmaxlocal} >  ${zmax}" | bc -l` ))
    then
        zmax=${zmaxlocal}
    fi

    paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | ${comando} )\
     <(awk '{print $3,$4}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | ${comando} ) \
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

    #i=1
    #lon=${newlon}
    #lat=${newlat}





    printMessage "Generando los frames de Viento (U y V) desde ${fecha} hasta ${fechamax}"
    #Recortamos los grids a la región seleccionada y transformamos la unidades
    sigmin=`date -u --date="${min:0:8} ${min:8:2} +3 hours" +%Y%m%d%H%M`
    while [ ${fecha} -le ${fechamax} ]
    do
        ncFile="${TMPDIR}/${fecha}.nc"
        ncFileU="${TMPDIR}/${fecha}_u.nc"
        ncFileV="${TMPDIR}/${fecha}_v.nc"

    #    gmt grdcut ${ncFile}?u10 ${Rgeog} -G${ncFileU}
    #    gmt grdcut ${ncFile}?v10 ${Rgeog} -G${ncFileV}
        ncFileU=${ncFile}?u10
        ncFileV=${ncFile}?v10

        nframesfecha=${nframes}
        if [ ${fecha} -le ${sigmin} ]
        then
            nframesfecha=${nframesinicio}
        fi


        if [ ${fecha} -eq ${min} ]
        then
    #        nframesfecha=$((${nframes}+${nframesloop}-1))
            nframesfecha=$((${nframesfecha}+${nframesloop}-1))
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

            read zminlocal zmaxlocal < <(awk 'BEGIN{min=9999; max=-9999}$5<min{min=$5}$5>max{max=$5}END{print min" "max}' ${TMPDIR}/dparticulas.txt)
            if (( `echo "${zminlocal} <  ${zmin}" | bc -l` ))
            then
                zmin=${zminlocal}
            fi
            if (( `echo "${zmaxlocal} >  ${zmax}" | bc -l` ))
            then
                zmax=${zmaxlocal}
            fi



    #        paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} ) <(awk '{print $3,$4,$5}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG}) |\
    #         awk -v w=${w} -v h=${h} '{printf "line %d,%d %d,%d\n", 1920*$1/w, 1080*(h-$2)/h, 1920*$3/w, 1080*(h-$4)/h}' > ${TMPDIR}/lineas.txt

             paste <( awk '{print $1,$2}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | ${comando})\
            <(awk '{print $3,$4}' ${TMPDIR}/dparticulas.txt | gmt mapproject ${RGEOG} ${JGEOG} | ${comando}) \
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


    #    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframerotulo}`.png
    #
    #    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
    #    printMessage "Generando frame con el texto para la fecha ${fecha}"
    #
    #    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    #    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}
    #
    #
    #    nframerotulo=$((nframerotulo+1))

        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +3 hours" +%Y%m%d%H%M`
    done

    if [ ${escalaViento} -eq 1 ]
    then

        ivar=$(( `echo ${indexescala[*]} | tr " " "\n" | sort -nr | head -n 1` + 1 ))
        index=${#indexescala[*]}
        indexescala[${index}]=${ivar}
        cargarVariable "uv"
#        calcularMinMax "${variablefondo}" ${min} ${max} ${stepinterp}
        printMessage "Generando Escala a partir de ${zmin}/${zmax} con fichero CPT ${cptGMT}"
        P=""

        echo ${tipoescala[*]}
        echo ${index} ${tipoescala[${index}]}
        if [ ${tipoescala[${index}]} == "h" ]
        then
            P="-p"
        fi
        ./crearescala.sh ${zmin}/${zmax} ${cptGMT} ${TMPDIR}/escala${ivar}.png  ${unidadEscala} "Viento" ${P} #2>> ${errorsFile}
    fi

#    exit


fi
#exit


nframerotulo=1
fecha=${minreal}
fechamax=${max}
printMessage "Generando frames de rotulos"
while [ ${fecha} -le ${fechamax} ]
do
    outputpng=${TMPDIR}/rotulo-`printf "%03d\n" ${nframerotulo}`.png

    rotuloFecha=`LANG=${idioma} TZ=:Europe/Madrid date -d @$(date  -u -d "${fecha:0:8} ${fecha:8:2}" +%s) +"%A %d, %H:00" | sed -e "s/\b\(.\)/\u\1/g"`
    printMessage "Generando frame con el texto para la fecha ${fecha}"

    convert -font ${fuentetitulo} -pointsize ${tamtitulo} -fill "${colortitulo}" -annotate +${xtitulo}+${ytitulo} "${titulo}" -page ${xboxtitulo}x${yboxtitulo} -gravity ${aligntitulo} \( -size 1920x1080 xc:transparent \) png32:${outputpng}
    convert -font ${fuentesubtitulo} -pointsize ${tamsubtitulo} -fill "${colorsubtitulo}" -annotate +${xsubtitulo}+${ysubtitulo} "${rotuloFecha}" -page ${xboxsubtitulo}x${yboxsubtitulo}  -gravity ${alignsubtitulo} ${outputpng} png32:${outputpng}


    nframerotulo=$((nframerotulo+1))

    if [ ${fecha} -eq ${minreal} ] && [ ${steprotulo} -eq  ${stepviento} ]
    then
        fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} -${desfasemin} hours" +%Y%m%d%H%M`
    fi

    fecha=`date -u --date="${fecha:0:8} ${fecha:8:2} +${steprotulo} hours" +%Y%m%d%H%M`
done



nescalas=${#indexescala[*]}
escalas=""

for ((i=0; i<${nescalas}; i++))
do
    ivar=${indexescala[${i}]}
    escalas="${escalas} -f image2 -i  ${TMPDIR}/escala${ivar}.png"

    if [ ${tipoescala[${i}]} == "h" ]
    then
        scalewidth=`convert ${TMPDIR}/escala${ivar}.png -ping -format "%w" info:`
        if [ ${scalewidth} -ge 1000 ]
        then
            convert ${TMPDIR}/escala${ivar}.png -resize 1000 ${TMPDIR}/escala${ivar}.png
            scalewidth=1000
        fi

        xscala[${i}]=$((${xscala[${i}]}-${scalewidth}/2))
    else
        scaleheight=`convert ${TMPDIR}/escala${ivar}.png -ping -format "%h" info:`
        if [ ${scaleheight} -ge 790 ]
        then
            convert ${TMPDIR}/escala${ivar}.png -resize 85x800\> ${TMPDIR}/escala${ivar}.png
            scaleheight=790
        fi

        yscala[${i}]=$((${yscala[${i}]}-${scaleheight}/2))
    fi
done

#Ponemos los rotulos

opciones=" -f image2 -i ${TMPDIR}/rotulo-001.png"
finicial=${nframesrotulo}
ffinal=$(( ${nframesinicio}+${nframesloop} -1 ))


#Fondo del mar
filtro="[$((${nframerotulo}+${nlogos}+${pintarViento}+${nescalas}+1))]loop=-1[mar];[mar][0]overlay[out];"

if [ ${pintarViento} -eq 1 ]
then
    filtro="${filtro}[1]fade=in:$((${nframesloop}-15)):15[viento];"
    framesViento="-f image2 -i ${TMPDIR}/%03d.png"
fi


if [ ! -z ${global} ] && [  ${global} -eq 1 ]
then

    filtro="${filtro}[out]setsar=sar=1,format=rgba[out];[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarPresion}+${pintarViento}+${nescalas}+2))]setsar=sar=1,format=rgba[sombra];[out][sombra]blend=all_mode=multiply:all_opacity=1,format=yuva422p10le[out];"
    frameSombra=" -f image2 -i ${filesombra}"
fi


framesUV=""
if [ ${pintarIntensidad} -eq 1 ]
then
#    filtro="[1]fade=in:$((${nframesloop}-15)):15[viento];[$((${nframerotulo}+${nlogos}+4))]fade=in:$((${nframesloop}-15)):15[uv];[0][uv]overlay[out];[out][viento]overlay[out];"
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarViento}+${nescalas}+2))]fade=in:$((${nframesloop}-15)):15[uv];[out][uv]overlay=shortest=1[out];"
    framesUV="-f image2 -i ${TMPDIR}/${variablefondo}%03d.png"
    echo ${var}
fi

if [ ${pintarViento} -eq 1 ]
then
    filtro="${filtro}[out][viento]overlay=shortest=1[out];"
fi


if [ ${pintarPresion} -eq 1 ]
then
    filtro="${filtro}[$((${nframerotulo}+${nlogos}+${pintarIntensidad}+${pintarViento}+${nescalas}+2))]fade=in:$((${nframesloop}-15)):15[press];[out][press]overlay=shortest=1[out];"
    framesPress="-f image2 -i ${TMPDIR}/msl%03d.png"
fi

#
#filtro="${filtro}[$((${pintarViento}+1))]loop=20:1:0[escala];[escala]fade=in:0:10[escala];[out][escala]overlay=x=${xscala}:y=${yscala}[out];\
#[out][$((${pintarViento}+2))]overlay=x=${xcartel}:y=${ycartel}[out];[out][$((${pintarViento}+3))]overlay=enable=between(n\,${finicial}\,${ffinal})"

#Colocamos las escalas
for ((i=0; i<${nescalas}; i++))
do
    filtro="${filtro}[$((${pintarViento}+${i}+1))]loop=20:1:0[escala${i}];[escala${i}]fade=in:0:10[escala${i}];[out][escala${i}]overlay=x=${xscala[${i}]}:y=${yscala[${i}]}[out];"
done

#Colocamos el cartel del título
filtro="${filtro}[out][$((${pintarViento}+${nescalas}+1))]overlay=x=${xcartel}:y=${ycartel}[out];[out][$((${pintarViento}+${nescalas}+2))]overlay=enable=between(n\,${finicial}\,${ffinal})"

#"[$((${nframerotulo}+${nlogos}+4))]fade=in:0:10[uv]"

# Opciones de filtro para solapar los rotulos
nframesrotuloi=$(( ${steprotulo}*60/${mins} ))
nstep=0
nstepinicio=1
j=0
nfinicio=${nframesinicio}
for((i=2; i<${nframerotulo}; i++))
do
    opciones="${opciones} -f image2 -i ${TMPDIR}/rotulo-`printf "%03d" ${i}`.png"

#    finicial=$(( (${i}-1)*${nframes}+${nframesloop} ))
#    ffinal=$(( ${i}*${nframes}+${nframesloop}-1 ))

    finicial=$(( ${nstepinicio}*${nframesinicio}+${nstep}*${nframes}+${nframesloop} + ${j}*${slowmotion}*${nframesrotuloi}  ))
    ffinal=$(( ${nstepinicio}*${nframesinicio}+${nstep}*${nframes}+${nframesloop} + (${j}+1)*${slowmotion}*${nframesrotuloi} -1 ))

    if [ $(( (${i} + ${desfasemin} -1) % (${stepviento}/${steprotulo}) )) -eq 0 ]
    then


        if [ ${nstepinicio} -lt 2 ]
        then
            nstepinicio=$((${nstepinicio}+1))
        else
            nstep=$((${nstep}+1))
        fi
        ffinal=$(( ${nstep}*${nframes}+${nframesloop}+${nframesinicio}*${nstepinicio} -1 ))
        j=0
    else
        j=$((${j}+1))
    fi

    filtro="${filtro}[out];[out][$((${i}+${nescalas}+${pintarViento}+1))]overlay=enable=between(n\,${finicial}\,${ffinal})"

done





#Ponemos los logos

logos=""
#filtro=""
if [ ${nlogos} -gt 0 ]
then
    logos="-f image2 -i ${logo[0]} "
    filtro="${filtro}[out];[out][$((${nframerotulo}+1+${pintarViento}+${nescalas}))]overlay=${xlogo[0]}:${ylogo[0]}"
fi

for((nlogo=1; nlogo<${nlogos}; nlogo++))
do
    logos="${logos} -f image2 -i ${logo[${nlogo}]} "
    filtro="${filtro};[out][$((${nframerotulo}+${nlogo}+1+${pintarViento}+${nescalas}))]overlay=${xlogo[${nlogo}]}:${ylogo[${nlogo}]}"
done


##Fondo del mar
#filtro="${filtro}[out];[$((${nframerotulo}+${nlogos}+3))]loop=-1[mar];[mar][out]overlay=shortest=1"







#fondoPNG="${TMPDIR}/kk%03d.png"


echo $filtro

ffmpeg -y -f image2 -i ${fondoPNG} ${framesViento} ${escalas} -f image2 -i  ${framescartel} ${opciones} ${logos} -i ${fondomar} ${framesUV} ${framesPress} ${frameSombra} -filter_complex ${filtro}  ${outputFile}
#rm -rf ${dir}
