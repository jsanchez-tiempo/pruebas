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

variables[acumprec,fprocesar]="procesarTasaPREC procesarPREC"
variables[acumprec,variables]="rateprec acumprec"
variables[acumprec,fpintar]="pintarPREC"
variables[acumprec,cpt]="cpt/precsat.cpt"
variables[acumprec,unidad]="l/m²"
variables[acumprec,isprec]=1
variables[prec,isprecacum]=1


variables[prec,fprocesar]="procesarTasaPREC procesarPREC"
variables[prec,variables]="rateprec acumprec"
variables[prec,fpintar]="pintarPREC"
variables[prec,cpt]="cpt/precsat.cpt"
variables[prec,unidad]="l/m²"
variables[prec,isprec]=1
variables[prec,isprecacum]=0

