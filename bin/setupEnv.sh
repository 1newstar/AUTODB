#!/bin/bash
##########################################################################
# Title: setupEnv.sh
# Purpose: This shell script setups the environment for the OUTT upgrade automation proces
#
# Created: MSH 
# Date: 8/5/2015
##########################################################################
echo "============================================================================"
echo " AUTODB Config File Setup"
echo ""
echo ""
echo "Script will create necessary parameters before upgrade automation can be run"
echo "----------------------------------------------------------------------------"
PARFILE=${WKDIR}/config/param_${ORACLE_SID}.txt
echo ORACLE_SID=${ORACLE_SID} > ${PARFILE}
echo WKDIR=${WKDIR} >> ${PARFILE}

#read -p "Enter ORACLE_HOME for the source DB: " OLD_ORA_HOME
#if [ ! -d ${OLD_ORA_HOME} ]; then echo "`date` Directory [${OLD_ORA_HOME}] not found."; fi
echo OLD_ORA_HOME=${OLD_ORA_HOME} >> ${PARFILE}

read -p "Enter the ORACLE_HOME for the target DB: " NEW_ORA_HOME
if [ ! -d ${NEW_ORA_HOME} ]; then echo "Directory [${NEW_ORA_HOME}] not found. Please check if directory exists and re-run utility."; exit 1; else echo NEW_ORA_HOME=${NEW_ORA_HOME} >> ${PARFILE};  fi


read -p "Email Address to Send Notifications: " ELIST
if [ `echo ${ELIST} | grep -c "@"` -eq 0 ]; then echo "`date` Invalid email address"; fi

echo ELIST=${ELIST} >> ${PARFILE}
echo MAILID=${ELIST} >> ${PARFILE}
