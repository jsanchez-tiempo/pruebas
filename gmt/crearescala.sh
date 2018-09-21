#!/bin/bash

#
#ncFile=$1
read zmin zmax < <(echo $1 | tr "/" " ")
cptFile=$2
output=$3
unidad=$4

TMPDIR=/tmp
heightdiv=45

# Diretorio temporal
dir=${TMPDIR}/`basename $(type $0 | awk '{print $3}').$$`
mkdir -p ${dir}



# Obtenemos el valor minimo y máximo del grid para pintar solo el rango de temperaturas que aparecen en el mapa
#read zmin zmax < <(gmt grdinfo -C -L0 ${ncFile} | awk '{print $6,$7}')
read min max sup < <(gmt makecpt -C${cptFile} -N | awk -v min=${zmin} -v max=${zmax} 'NR==1 && min<$1 {printf "%s ",$1} min>=$1 && min<$3 {printf "%s ",$1} max<=$3 && max>$1{print $3" "0} END{if(max>$3) print $3" "1}')
gmt makecpt -C${cptFile} -G${min}/${max} -N -I -Fr > ${dir}/tmp.cpt


# calculamos la altura de la escala multiplicando 45 pixeles por el número de divisiones
scaleheight=`wc -l ${dir}/tmp.cpt | awk -v height=${heightdiv} '{print $1*height}'`

offset=0
if [ ${sup} -eq 1 ]
then
    scaleheight=$(( ${scaleheight} + ${heightdiv}/2 ))
    offset=$(( ${heightdiv}/2 ))
fi

convert -size 35x${scaleheight} xc:transparent ${output}


i=0
#echo $sup
if [ ${sup} -eq 1 ]
then
    color=`gmt makecpt -Fr -C${cptFile} | sed -n '/^\s*F/p' | awk '{print "rgb("$2")"}'| tr "/" ","`
#    echo $color
    convert ${output} -stroke black -fill "${color}" -draw "polygon 0,$((${heightdiv}/2-1)) 17,$(( ${i}*${heightdiv}-1)) 34,$((${heightdiv}/2-1)) " ${output}
fi

#exit
# Para cada color del fichero cpt pintamos su cuadrícula

while read color
do
#    echo ${color}
    convert ${output} -stroke black -fill "${color}" -draw "rectangle 0,$((${offset}+$i*${heightdiv}-1)), 34,$(( ${offset}+(${i}+1)*${heightdiv}-1 ))" ${output}
    i=$(($i+1))
done < <(awk '{print "rgb("$2")"}' ${dir}/tmp.cpt| tr "/" ",")




# Pintamos un marco con un ancho de 2 pixeles
#convert ${output} -stroke black -strokewidth 2 -fill "transparent" -draw "rectangle 0,${offset}, 34,$((${scaleheight}-1))" ${output}
convert ${output} -stroke black -strokewidth 2 -fill "transparent" -draw "polygon 34,${offset} 17,0 0,${offset} 0,$((${scaleheight}-1)) 34,$((${scaleheight}-1))" ${output}


# Creamos el efecto sombra para la escala y ampliamos el lienzo para poder pintar los rotulos
#convert -size 85x$((${scaleheight}+45)) xc:none -fill 'gray' -draw "rectangle 5,35 40,$((${scaleheight}+35))" -blur 0x1 ${dir}/fescala.png
convert -size 85x$((${scaleheight}+45)) xc:none -fill 'gray' -draw "polygon 40,$((35+${offset})) 22,35 5,$((35+${offset})) 5,$((${scaleheight}+35)) 40,$((${scaleheight}+35))" -blur 0x1 ${dir}/fescala.png
composite -geometry +4+34 ${output} ${dir}/fescala.png ${output}


# Pintamos los valores de la escala
i=0
while read rotulo
do
    convert -size 50x30 xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity east \
    -annotate +0+6 "${rotulo}" \( +clone -background none -shadow 80x2+1+1 \) +swap  \
    -flatten miff:- | composite -geometry +33+$(( (${scaleheight}+15)-${i}*${heightdiv} )) - ${output} ${output}

    i=$(($i+1));
done < <(awk '{print $1}' ${dir}/tmp.cpt)


# Pintamos el valor máximo de la escala
rotulo=`awk '{print $3}'  ${dir}/tmp.cpt | tail -n 1`
convert -size 50x30 xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity east \
-annotate +0+6 "${rotulo}" \( +clone -background none -shadow 80x2+1+1 \) +swap  \
-flatten miff:- | composite -geometry +33+$(( (${scaleheight}+15)-$i*${heightdiv} )) - ${output} ${output}

# Pintamos el rótulo de la unidad
convert -size 75x25 xc:none -font Helvetica-Bold -pointsize 24 -fill white -gravity west \
-annotate +0+0 ${unidad} \( +clone -background none -shadow 80x2+1+1 \) +swap  \
-flatten miff:- | composite -geometry +0+0 - ${output} ${output}

rm -rf ${dir}
