#!/bin/bash
################################################################################################
#Title: before_upg_restorepnt.sh
#Purpose: This script creates a restore point for the 11g Environment before 12c Upgrade                
#                                                           
#Date: 8/26/15                                                                  #Modified: Huzaifa Z.                                                                                 
################################################################################################
. $WKDIR/bin/11g_Env.sh

export LOGDIR=$WKDIR/logs/${ORACLE_SID}
export ORACLE_SID=`grep ORACLE_SID $PARFILE  | awk -F"=" '{print $2}'`
export ORACLE_HOME=`grep OLD_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`

#MB Added error catching in the SQL
#HZ Dont quit on error, 
#Catch if restore point exists then to drop or else it will error out
CREATERESTORE=""
DROPRESTORE=""
CREATERP=${LOGDIR}/upgrade/before_12c_restorepoint.log
if [ -f ${FAFLAG} ]; then
	CREATERESTORE="create restore point before_12c_upgrade guarantee flashback database;"
$ORACLE_HOME/bin/sqlplus "/as sysdba" <<EOF > ${CREATERP}
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT NAME FROM V\$RESTORE_POINT;
exit sql.sqlcode
EOF
	if [ $? -ne 0 ]; then
		echo "`date` before_upg_restorepnt.sh failed. Error: `grep ORA- ${CREATERP} | head -1`"
		rm ${OPTION2} > /dev/null
		exit 1
	else
		if [ `grep -c BEFORE_12C_UPGRADE ${CREATERP}` -eq 1 ]; then
			echo "`date` Restore point [BEFORE_12C_UPGRADE] found. This restore point will be dropped and recreated."
			DROPRESTORE="drop restore point before_12c_upgrade;"
		fi
	fi
fi

$ORACLE_HOME/bin/sqlplus "/as sysdba" <<EOF > ${CREATERP}
WHENEVER SQLERROR EXIT SQL.SQLCODE
set echo on
select * from gV\$encryption_wallet;
select * from gv\$restore_point;
${DROPRESTORE}
${CREATERESTORE}
select * from gv\$restore_point;
exit sql.sqlcode
EOF
#HZ - Michael we need to have script continue even if its not set up for archivelog mode, 
#HZ - Display error and then continue to the next stage in upgrade
if [ $? -ne 0 ]; then
   echo "`date` before_upg_restorepnt.sh failed. Error: `grep ORA- ${CREATERP} | head -1`"
   rm ${OPTION2} > /dev/null
   exit 1
else
	if [ `echo ${CREATERESTORE} | grep -c flashback` -eq 1 ]; then
		echo "`date` Restore Point: before_12c_upgrade created."
	else
		echo "`date` Creation of restore point skipped. Archivelog or Flashback is turned off."
	fi
fi
