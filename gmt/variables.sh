#!/bin/bash

###############################################################################
# Definición de variables que se pueden mostrar en las animaciones:
#
# - fprocesar: función (o funciones) para obtener los grids de la variable.
# - fpintar: función para pintar los frames de la variable.
# - cpt: fichero CPT con el que se pinta la variable.
# - unidad: unidad que aparece en la escala de la variable.
# - istransparent: si se transforma un canal de color a canal alfa (nubes).
# - isprec: es una variable de precipitación.
# - isprecacum: es precipitación acumulada.
# - maxalcance: alcance máximo hasta el que se puede aplicar la función fprocesar.
#
#
# Juan Sánchez Segura <jsanchez.tiempo@gmail.com>
# Marcos Molina Cano <marcosmolina.tiempo@gmail.com>
# Guillermo Ballester Valor <gbvalor@gmail.com>                      07/11/2018
###############################################################################


declare -A variables

## Viento medio en superficie
variables[uv,fprocesar]="procesarViento"
variables[uv,fpintar]="pintarViento"
variables[uv,cpt]="cpt/v10m_201404.cpt"
variables[uv,unidad]="km/h"

## Viento medio a 300hpa
variables[uv300,fprocesar]="procesarViento300"
variables[uv300,fpintar]="pintarViento300"
variables[uv300,cpt]="cpt/velv300_201810.cpt"
variables[uv300,unidad]="km/h"

## Racha máxima de viento en superficie
variables[uvracha,fprocesar]="procesarRachasViento"
variables[uvracha,fpintar]="pintarViento"
variables[uvracha,cpt]="cpt/v10m_201404.cpt"
variables[uvracha,unidad]="km/h"

## Altura geopotencial a 500hpa
variables[gh500,fprocesar]="procesarGH500"
variables[gh500,fpintar]="pintarGH500"
variables[gh500,cpt]="cpt/geop500.cpt"
variables[gh500,unidad]="dam"

## Temperatura a 500hpa
variables[t500,fprocesar]="procesarT500"
variables[t500,fpintar]="pintarT500"
variables[t500,cpt]="cpt/temp500.cpt"
variables[t500,unidad]="°C"

## Temperatura a 850hpa
variables[t850,fprocesar]="procesarT850"
variables[t850,fpintar]="pintarT850"
variables[t850,cpt]="cpt/temp850.cpt"
variables[t850,unidad]="°C"

## Presión a nivel del mar
variables[press,fprocesar]="procesarPresion"

## Cobertura nubosa total
variables[nubes,fprocesar]="procesarNubes"
variables[nubes,fpintar]="pintarNubes"
variables[nubes,cpt]="cpt/tccvideos.cpt"
variables[nubes,unidad]="%"
variables[nubes,istransparent]=1

## Precipitación acumulada
variables[acumprec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[acumprec,variables]="rateprec acumprec"
variables[acumprec,maxalcance]="72 9999"
variables[acumprec,fpintar]="pintarPREC"
variables[acumprec,cpt]="cpt/precsat.cpt"
variables[acumprec,unidad]="l/m²"
variables[acumprec,isprec]=1
variables[acumprec,isprecacum]=1

## Precipitación prevista
variables[prec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[prec,variables]="rateprec acumprec"
variables[prec,maxalcance]="72 9999"
variables[prec,fpintar]="pintarPREC"
variables[prec,cpt]="cpt/precsat.cpt"
variables[prec,unidad]="l/m²"
variables[prec,isprec]=1
variables[prec,isprecacum]=0

## Nieve acumulada
variables[acumnieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[acumnieve,variables]="ratenieve acumnieve"
variables[acumnieve,maxalcance]="72 9999"
variables[acumnieve,fpintar]="pintarPREC"
variables[acumnieve,cpt]="cpt/nievesat2.cpt"
variables[acumnieve,unidad]="cm"
variables[acumnieve,isprec]=1
variables[acumnieve,isprecacum]=1

## Nieve prevista
variables[nieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[nieve,variables]="ratenieve acumnieve"
variables[nieve,maxalcance]="72 9999"
variables[nieve,fpintar]="pintarPREC"
variables[nieve,cpt]="cpt/nievesat2.cpt"
variables[nieve,unidad]="l/m²"
variables[nieve,isprec]=1
variables[nieve,isprecacum]=0

