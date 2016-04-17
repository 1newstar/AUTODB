#!/bin/bash
####################################################################
#Title: shtdwnSrc.sh
#Description: Brings source database down, and stops listener service. 11g Environment is set prior to execution of this script. It is recommended to run this script at the end of prior the main database upgrade script uprade.sh
#
# Created 8/11/15 Huzaifa.Z 
#####################################################################

. $WKDIR/bin/11g_Env.sh
export ORACLE_SID=`grep ORACLE_SID $PARFILE  | awk -F"=" '{print $2}'`
export LOGDIR=$WKDIR/logs/${ORACLE_SID}
export ORACLE_HOME=`grep OLD_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`
SHTDWNLOG=${LOGDIR}/upgrade/shtdwnSrc.log

echo "`date` Preparing to shut down database"
#MB Added error capture in the SQL and listener
#HZ Dont want the script to exit, should check if database is open then shutdown, if already shutdown then continue.
if [ `ps -ef | grep pmon | grep ora_pmon_${ORACLE_SID} | grep -v grep | wc -l` -eq 0 ]; then
	echo "`date` Database [${ORACLE_SID}] is currently down."
else
sqlplus -s "/ as sysdba"  <<EOF > $SHTDWNLOG
WHENEVER SQLERROR EXIT SQL.SQLCODE
show parameter db_name
set lines 500 pages 500
shutdown immediate
spool off;
exit sql.sqlcode
EOF
#HZ Condition is exiting script prematurely
#Display ORA number/ description before exit
	if [ $? -ne 0 ]; then
		echo "`date` ShtdwnSrc.sh failed. Error: `grep ORA- $SHTDWNLOG | head -1`"
		rm ${OPTION2} > /dev/null
		exit 1
	else
	echo "`date` Shutdown of database complete."
	fi
fi

#HZ should check if listener is started then stop, if already stopped then continue
#echo "`date` Stopping listener service..."
#Depending on environment ORACLE_SID must be specified after stop command
#lsnrctl stop $ORACLE_SID
#if [ `lsnrctl status | grep -c TNS-` -ne 0 ]; then
#if [ `ps -ef | grep tnslsnr | grep LISTENER | wc -l` -eq 0 ]; then
#	echo "`date` Listener is currently down."
#else
#	lsnrctl stop >> ${LOGDIR}/pre/shtdwnSrc.log
#HZ Giving out error message each time need to check
#Display error message opposed to generic state
#	if [ $? -ne 0 ]; then
#		echo "`date` shtdwnSrc.sh failed. Error: `grep TNS- $SHTDWNLOG | head -1`"
#	else
#		echo "`date` Shutdown of Listener complete."
#	fi
#fi

