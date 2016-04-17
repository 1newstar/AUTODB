#!/bin/bash
#########################################################################
# Title: upgrade.sh
# Purpose: Upgrade database from 11g to 12c 
#
# Created: 8/11/15
# Modified: Huzaifa Z.
##########################################################################


#Sets 12c environment before running upgrade
. $WKDIR/bin/12c_Env.sh
export LOGDIR=$WKDIR/logs/${ORACLE_SID}


echo "#################################################################"
echo "              YOU ARE NOW STARTING THE UPGRADE STAGE             "
echo ""
echo ""
echo " NOTE: Make sure all preupgrade tasks have been completed         "
echo " Restore point will be created and Database will be brought down  "
echo ""
echo "##################################################################" 
echo ""
echo ""
echo ""
read -p "              Do you wish to continue? (y/n)" choice
case "$choice" in
        y|Y ) echo "`date` Starting upgrade script...";;
        n|N ) rm ${OPTION2} > /dev/null; exit 1;;
        * ) echo "invalid";;
esac
#Cat  $ORACLE_HOME/cfgtoollogs/${ORACLE_SID}/upgrade/upg_summary.log > send to email if possible
#MB Added error handling
#HZ Not executing script with if condition set. Needs correction
#Ensure oracle db is down before startup upgrade

#Runs Upgrade Pre-Reqs
$WKDIR/bin/enablearchiveflash.sh
if [ $? -ne 0 ]; then 
	exit 1; fi
$WKDIR/bin/before_upg_restorepnt.sh
if [ $? -ne 0 ]; then
        exit 1; fi
$WKDIR/bin/shtdwnSrc.sh
if [ $? -ne 0 ]; then
        exit 1; fi
#Runs Oracle CAT UPGRADE
$ORACLE_HOME/bin/sqlplus "/as sysdba" <<EOF > ${LOGDIR}/upgrade/upgradesh.log
WHENEVER SQLERROR EXIT SQL.SQLCODE
set echo on
startup upgrade
exit sql.sqlcode
EOF
if [ $? -ne 0 ]; then
	echo "`date` upgrade.sh failed. Error: `grep ORA- ${LOGDIR}/upgrade/upgradesh.log | head -1`"; rm ${OPTION2} > /dev/null; exit 1 ;
else
	echo "`date` startup upgrade complete."
fi

cd ${ORACLE_HOME}/rdbms/admin
mkdir -p ${ORACLE_HOME}/diagnostics/${ORACLE_SID}
${ORACLE_HOME}/perl/bin/perl catctl.pl -n 6 -l ${ORACLE_HOME}/diagnostics/${ORACLE_SID} catupgrd.sql
cd ${WKDIR}
if [ $? -ne 0 ]; then
	echo "`date` upgrade.sh failed. Unable to run catupgrd.sql"; rm ${OPTION2} > /dev/null; exit 1;
else
	echo "`date` catupgrd.sql complete."
fi
