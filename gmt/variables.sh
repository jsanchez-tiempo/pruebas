#!/bin/bash

declare -A variables

variables[uv,fprocesar]="procesarViento"
variables[uv,fpintar]="pintarViento"
variables[uv,cpt]="cpt/v10m_201404.cpt"
variables[uv,unidad]="km/h"

variables[gh500,fprocesar]="procesarGH500"
variables[gh500,fpintar]="pintarGH500"
variables[gh500,cpt]="cpt/geop500.cpt"
variables[gh500,unidad]="dam"

variables[t850,fprocesar]="procesarT850"
variables[t850,fpintar]="pintarT850"
variables[t850,cpt]="cpt/temp850.cpt"
variables[t850,unidad]="°C"

variables[nubes,fprocesar]="procesarNubes"
variables[nubes,fpintar]="pintarNubes"
variables[nubes,cpt]="cpt/tccvideos.cpt"
variables[nubes,unidad]="%"
variables[nubes,istransparent]=1

variables[acumprec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[acumprec,variables]="rateprec acumprec"
variables[acumprec,fpintar]="pintarPREC"
variables[acumprec,cpt]="cpt/precsat.cpt"
variables[acumprec,unidad]="l/m²"
variables[acumprec,isprec]=1
variables[acumprec,isprecacum]=1

variables[prec,fprocesar]="procesarTasaLluvia procesarLluvia"
variables[prec,variables]="rateprec acumprec"
variables[prec,fpintar]="pintarPREC"
variables[prec,cpt]="cpt/precsat.cpt"
variables[prec,unidad]="l/m²"
variables[prec,isprec]=1
variables[prec,isprecacum]=0


variables[acumnieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[acumnieve,variables]="ratenieve acumnieve"
variables[acumnieve,fpintar]="pintarPREC"
variables[acumnieve,cpt]="cpt/nievesat2.cpt"
variables[acumnieve,unidad]="l/m²"
variables[acumnieve,isprec]=1
variables[acumnieve,isprecacum]=1

variables[nieve,fprocesar]="procesarTasaNieve procesarNieve"
variables[nieve,variables]="ratenieve acumnieve"
variables[nieve,fpintar]="pintarPREC"
variables[nieve,cpt]="cpt/nievesat2.cpt"
variables[nieve,unidad]="l/m²"
variables[nieve,isprec]=1
variables[nieve,isprecacum]=0

