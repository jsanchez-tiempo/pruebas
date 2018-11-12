#!/bin/bash



source defaults.cfg

read zmin zmax < <(echo $1 | tr "/" " ")
cptFile=$2
output=$3
unidad=$4
horizontal=0

if [ ! -z $5 ] && [ $5 == "-p" ]
then
    horizontal=1
else
    titulo=$5
fi

if [ ! -z $6 ] && [ $6 == "-p" ]
then
    horizontal=1
fi



sizediv=45



# Diretorio temporal
dir=${TMPBASEDIR}/`basename $(type $0 | awk '{print $3}').$$`
mkdir -p ${dir}


# Nombre del script.
scriptName=`basename $0`

# Función que define la ayuda sobre este script.
function usage() {
      echo
      echo "Genera una escala de colores en formáto PNG"
      echo
      echo "Uso:"
      echo "${scriptName} zmin/zmax cptfile outputfile unidad [titulo] [-p]"
}





if [ ${horizontal} -eq 0 ]
then
    I="-I"
fi

# Obtenemos el valor minimo y máximo del grid para pintar solo el rango de temperaturas que aparecen en el mapa
#read zmin zmax < <(${GMT} grdinfo -C -L0 ${ncFile} | awk '{print $6,$7}')
read min max sup < <(${GMT} makecpt -C${cptFile} -N | awk -v min=${zmin} -v max=${zmax} 'NR==1 && min<$1 {printf "%s ",$1} min>=$1 && min<$3 {printf "%s ",$1} max<=$3 && max>$1{print $3" "0} END{if(max>$3) print $3" "1}')
${GMT} makecpt -C${cptFile} -G${min}/${max} -N ${I} -Fr > ${dir}/tmp.cpt


# calculamos la altura de la escala multiplicando 45 pixeles por el número de divisiones
scalesize=`wc -l ${dir}/tmp.cpt | awk -v size=${sizediv} '{print $1*size}'`
if [ ${horizontal} -eq 1 ]
then
    scaleheight=35
    scalewidth=${scalesize}
else
    scaleheight=${scalesize}
    scalewidth=35
fi

offset=0
if [ ${sup} -eq 1 ]
then
    if [ ${horizontal} -eq 1 ]
    then
        scalewidth=$(( ${scalewidth} + ${sizediv}/2 ))
    else
        scaleheight=$(( ${scaleheight} + ${sizediv}/2 ))
    fi
    offset=$(( ${sizediv}/2 ))
fi




convert -size ${scalewidth}x${scaleheight} xc:transparent ${output}



i=0
#echo $sup
if [ ${sup} -eq 1 ]
then
    color=`${GMT} makecpt -Fr -C${cptFile} | sed -n '/^\s*F/p' | awk '{print "rgb("$2")"}'| tr "/" ","`
#    echo $color
    if [ ${horizontal} -eq 1 ]
    then
        dims="$((${scalewidth}-${sizediv}/2)),0 ${scalewidth},$((${scaleheight}/2)) $((${scalewidth}-${sizediv}/2)),$((${scaleheight}-1))"
    else
        dims="0,$((${sizediv}/2-1)) $((${scalewidth}/2)),$(( ${i}*${sizediv}-1)) $((${scalewidth}-1)),$((${sizediv}/2-1))"
    fi

    ${CONVERT} ${output} -stroke black -fill "${color}" -draw "polygon ${dims}" ${output}
fi


# Para cada color del fichero cpt pintamos su cuadrícula

while read color
do

    if [ ${horizontal} -eq 1 ]
    then
        dims="$(($i*${sizediv}-1)),0, $(( (${i}+1)*${sizediv}-1 )),$((${scaleheight}-1))"
    else
        dims="0,$((${offset}+$i*${sizediv}-1)), $((${scalewidth}-1)),$(( ${offset}+(${i}+1)*${sizediv}-1 ))"
    fi

    ${CONVERT} ${output} -stroke black -fill "${color}" -draw "rectangle ${dims}" ${output}
    i=$(($i+1))
done < <(awk '{print "rgb("$2")"}' ${dir}/tmp.cpt| tr "/" ",")

#exit




# Pintamos un marco con un ancho de 2 pixeles
if [ ${horizontal} -eq 1 ]
then
    dims="0,0 $((${scalewidth}-1-${offset})),0 $((${scalewidth}-1)),$((${scaleheight}/2)) $((${scalewidth}-1-${offset})),$((${scaleheight}-1)) 0,$((${scaleheight}-1))"
else
    dims="$((${scalewidth-1})),${offset} $((${scalewidth}/2)),0 0,${offset} 0,$((${scaleheight}-1)) $((${scalewidth-1})),$((${scaleheight}-1))"
fi

#${CONVERT} ${output} -stroke black -strokewidth 2 -fill "transparent" -draw "rectangle 0,${offset}, 34,$((${scaleheight}-1))" ${output}
${CONVERT} ${output} -stroke black -strokewidth 2 -fill "transparent" -draw "polygon ${dims}" ${output}
#exit




dy=45
dx=75
dtitulo=0
if [ ! -z ${titulo} ]
then
    if [ ${horizontal} -eq 1 ]
    then
        dtitulo=25
        dx=$((${dx}+35))
    else
        dtitulo=30
        dy=$((${dy}+${dtitulo}))
    fi

fi

#echo $offset
# Creamos el efecto sombra para la escala y ampliamos el lienzo para poder pintar los rotulos
if [ ${horizontal} -eq 1 ]
then
    xsize=$((${scalewidth}+${dx}))
    ysize=$((${scaleheight}+50))
    dims="$((${dx}-20)),5\
         $((${scalewidth}-20-${offset}+${dx})),5\
         $((${scalewidth}-20+${dx})),$((5+${scaleheight}/2))\
         $((${scalewidth}-20-${offset}+${dx})),$((${scaleheight}+5))\
         $((${dx}-20)),$((${scaleheight}+5))"
#         echo $offset
#         echo $dims
    dimscomposite="+$((${dx}-21))+4"
else
    xsize=$((${scalewidth}+50))
    ysize=$((${scaleheight}+${dy}))
    dims="$((${scalewidth}+5)),$((${dy}-10+${offset}))\
            $((5+${scalewidth}/2)),$((${dy}-10))\
            5,$((${dy}-10+${offset}))\
            5,$((${scaleheight}+${dy}-10))\
            $((${scalewidth}+5)),$((${scaleheight}+${dy}-10))"
    dimscomposite=+4+$((${dy}-11))
fi



${CONVERT} -size ${xsize}x${ysize} xc:none -fill 'gray' -draw "polygon ${dims}" -blur 0x1 ${dir}/fescala.png
composite -geometry ${dimscomposite} ${output} ${dir}/fescala.png ${output}

#exit

# Pintamos los valores de la escala
i=0
while read rotulo
do
    if [ ${horizontal} -eq 1 ]
    then
        pos="south"
        posdims="+$(( ${dx}+${i}*${sizediv}-40 ))+$((${scaleheight}-2))"
        dimsnumero="40x45"

    else
        pos="east"
        posdims="+$((${scalewidth}-2))+$(( (${scaleheight}+${dtitulo}+15)-${i}*${sizediv} ))"
        dimsnumero="50x40"

    fi

    ${CONVERT} -size ${dimsnumero} xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity ${pos} \
    -annotate +0+0 "${rotulo}" \( +clone -background none -shadow 80x2+1+1 \) +swap  \
    -flatten miff:- | composite -geometry ${posdims} - ${output} ${output}

    i=$(($i+1));
done < <(awk '{print $1}' ${dir}/tmp.cpt)

#exit

# Pintamos el valor máximo de la escala
if [ ${horizontal} -eq 1 ]
then
    pos="south"
    posdims="+$(( ${dx}+${i}*${sizediv}-40 ))+$((${scaleheight}-2))"
    dimsnumero="40x45"

else
    pos="east"
    posdims="+$((${scalewidth}-2))+$(( (${scaleheight}+${dtitulo}+15)-${i}*${sizediv} ))"
    dimsnumero="50x40"

fi
rotulo=`awk '{print $3}'  ${dir}/tmp.cpt | tail -n 1`
${CONVERT} -size ${dimsnumero} xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity ${pos} \
-annotate +0+0 "${rotulo}" \( +clone -background none -shadow 80x2+1+1 \) +swap  \
-flatten miff:- | composite -geometry ${posdims} - ${output} ${output}

#exit

# Pintamos el rótulo de la unidad
if [ ${horizontal} -eq 1 ]
then
    dims="+0+$((10+${dtitulo}))"
else
    dims="+0+${dtitulo}"
fi

${CONVERT} -size 75x25 xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity west \
-annotate +0+0 ${unidad} \( +clone -background none -shadow 80x2+1+1 \) +swap  \
-flatten miff:- | composite -geometry ${dims} - ${output} ${output}

#exit


if [ ${horizontal} -eq 1 ]
then
    dims="+0+5"
else
    dims="+0+0"
fi

if [ ! -z ${titulo} ]
then
    # Pintamos el rótulo de la unidad
    ${CONVERT} -size 95x25 xc:none -font Helvetica-Bold -pointsize 26 -fill white -gravity west \
    -annotate +0+0 ${titulo} \( +clone -background none -shadow 80x2+1+1 \) +swap  \
    -flatten miff:- | composite -geometry ${dims} - ${output} ${output}
fi

rm -rf ${dir}
