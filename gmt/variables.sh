#!/bin/bash

declare -A variables

variables[uv,fprocesar]="procesarViento"
variables[uv,fpintar]="pintarViento"
variables[uv,cpt]="cpt/v10m_201404.cpt"
variables[uv,unidad]="km/h"

variables[uv300,fprocesar]="procesarViento300"
variables[uv300,fpintar]="pintarViento300"
variables[uv300,cpt]="cpt/velv300_201810.cpt"
variables[uv300,unidad]="km/h"

variables[uvracha,fprocesar]="procesarRachasViento"
variables[uvracha,fpintar]="pintarViento"
variables[uvracha,cpt]="cpt/v10m_201404.cpt"
variables[uvracha,unidad]="km/h"

variables[gh500,fprocesar]="procesarGH500"
variables[gh500,fpintar]="pintarGH500"
variables[gh500,cpt]="cpt/geop500.cpt"
variables[gh500,unidad]="dam"

variables[t500,fprocesar]="procesarT500"
variables[t500,fpintar]="pintarT500"  # sin implementar
variables[t500,cpt]="cpt/temp500.cpt"
variables[t500,unidad]="°C"

variables[t850,fprocesar]="procesarT850"
variables[t850,fpintar]="pintarT850"
variables[t850,cpt]="cpt/temp850.cpt"
variables[t850,unidad]="°C"

variables[press,fprocesar]="procesarPresion"

variables[nubes,fprocesar]="procesarNubes"
variables[nubes,fpintar]="pintarNubes"
variables[nubes,cpt]="cpt/tccvideos.cpt"
variables[nubes,unidad]="%"
variables[nubes,istransparent]=1

variables[acumprec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[acumprec,variables]="rateprec acumprec"
variables[acumprec,maxalcance]="72 9999"
variables[acumprec,fpintar]="pintarPREC"
variables[acumprec,cpt]="cpt/precsat.cpt"
variables[acumprec,unidad]="l/m²"
variables[acumprec,isprec]=1
variables[acumprec,isprecacum]=1

variables[prec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[prec,variables]="rateprec acumprec"
variables[prec,maxalcance]="72 9999"
variables[prec,fpintar]="pintarPREC"
variables[prec,cpt]="cpt/precsat.cpt"
variables[prec,unidad]="l/m²"
variables[prec,isprec]=1
variables[prec,isprecacum]=0


variables[acumnieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[acumnieve,variables]="ratenieve acumnieve"
variables[acumnieve,maxalcance]="72 9999"
variables[acumnieve,fpintar]="pintarPREC"
variables[acumnieve,cpt]="cpt/nievesat2.cpt"
variables[acumnieve,unidad]="l/m²"
variables[acumnieve,isprec]=1
variables[acumnieve,isprecacum]=1

variables[nieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[nieve,variables]="ratenieve acumnieve"
variables[nieve,maxalcance]="72 9999"
variables[nieve,fpintar]="pintarPREC"
variables[nieve,cpt]="cpt/nievesat2.cpt"
variables[nieve,unidad]="l/m²"
variables[nieve,isprec]=1
variables[nieve,isprecacum]=0

