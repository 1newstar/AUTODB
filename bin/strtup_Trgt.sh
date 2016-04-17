#!/bin/bash
#-----------------------------------------------------------------------
# Title: strtup_Trgt.sh
# Details: Run script after database upgrade is complete 
# Description: Starts up target database after upgrade and starts listener service
# Created 8/11/15 Huzaifa.Z 
#---------------------------------------------------------------------
#echo "`date` Setting environment..."
. $WKDIR/bin/12c_Env.sh

export LOGDIR=$WKDIR/logs/${ORACLE_SID}
export ORACLE_HOME=`grep NEW_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`
STRTUPLOG=${LOGDIR}/upgrade/strtuptrg.log
#HZ error handling 
echo "`date` Preparing to startup  database..."
sqlplus -s "/ as sysdba"  <<EOF > ${STRTUPLOG}
WHENEVER SQLERROR EXIT SQL.SQLCODE
select 'name' from dual ;
exit sql.sqlcode
EOF

if [ $? -ne 0 ]; then
sqlplus -s "/ as sysdba"  <<EOF >> ${STRTUPLOG}
WHENEVER SQLERROR EXIT SQL.SQLCODE
startup open
exit sql.sqlcode
EOF
        if [ $? -ne 0 ]; then
                echo "`date` strtup_Trgt.sh failed. Startup of database failed. Error: `grep ORA- ${STRTUPLOG} | head -1`"
                rm ${OPTION2} > /dev/null
                exit 1
        else
                echo "`date` Startup of database complete."
        fi
else
	echo "`date` Database [${ORACLE_SID}] is already up."
fi

#echo "`date` Starting listener service..."
#lsnrctl start $ORACLE_SID > ${STRTUPLOG}
#MB Got this error TNS-01151: Missing listener name, DEV11g, in LISTENER.ORA
#if [ `ps -ef | grep tnslsnr | grep LISTENER | wc -l` -ne 0 ]; then
#        echo "`date` Listener is currently up."
#else
#        lsnrctl stop >> ${STRTUPLOG}
#HZ Giving out error message each time need to check
#Display error message opposed to generic state
#        if [ $? -ne 0 ]; then
#                echo "`date` Shutdown of listener failed. Error: `grep TNS- ${STRTUPLOG} | head -1`"
#        else
#                echo "`date` Startup of Listener complete."
#        fi
#fi

#lsnrctl start >> ${STRTUPLOG}
#HZ Giving out error message each time need to check
#Display error message opposed to generic state
#if [ $? -ne 0 ]; then
#        echo "`date` strtup_Trgt.sh failed. Startup of listener failed. Error: `grep TNS- ${STRTUPLOG} | head -1`"
#	rm ${OPTION2} > /dev/null
#        exit 1
#else
#        echo "`date` Listener is Up."
#fi

