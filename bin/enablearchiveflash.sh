#!/bin/bash 
. ${WKDIR}/bin/11g_Env.sh
HOSTNAME=`hostname`
LOGDIR=$WKDIR/logs/${ORACLE_SID}
rm -f ${FAFLAG} > /dev/null
FALOG=${LOGDIR}/upgrade/flasharchive.log
export FAFLAG=${WKDIR}/.flasharchive_${ORACLE_SID}
ARCHIVEENABLE=${LOGDIR}/upgrade/archiveenable.log
FLASHENABLE=${LOGDIR}/upgrade/flashenable.log
rm -f ${FAFLAG} > /dev/null
export UPGRADE_LOG=$LOGDIR/upgrade/upgrade.log

UpdateLog ()
{
   msg="$1"
   echo "$msg" | tee -a $UPGRADE_LOG
}

echo "ORACLE_HOME=${ORACLE_HOME}"
export PATH=$PATH:/usr/lib

#MB Verify if the directories are existing:
check_directory () {
if [ ! -d $1 ]; then
        UpdateLog "Directory [$1] not existing."
fi
}

check_file () {
if [ ! -f $1 ]; then
	UpdateLog "File [$1] not existing."
else
	UpdateLog "`ls -ltr $1`"
fi
}

if [ `uname -a | grep -c Linux` -ne 0 ]; then
        ORATAB=/etc/oratab
else
        ORATAB=/var/opt/oracle/oratab
fi

if [ `grep -c ${ORACLE_SID} ${ORATAB}` -eq 0 ]; then
        Updatelog "ORACLE_SID not found in oratab"
	rm ${OPTION1} > /dev/null
        exit 1
fi

$ORACLE_HOME/bin/sqlplus -s "/as sysdba" <<EOF > ${FALOG}
WHENEVER SQLERROR EXIT SQL.SQLCODE
set heading off
SELECT LOG_MODE||':'||FLASHBACK_ON FROM V\$DATABASE;
exit SQL.SQLCODE
EOF
if [ $? -ne 0 ]; then
	UpdateLog "enablearchiveflash.sh failed. Error: `grep ORA- ${FALOG} | head -1`"
else
        if [ `grep -c "NOARCHIVELOG:" ${FALOG}` -eq 1 ]; then
                UpdateLog "Warning. ARCHIVELOG MODE: NOARCHIVELOG"
		read -p "`date` Do you want to enable Archivelog? [Y/N] " INPUTA
		if [[ "${INPUTA}" == "Y" || "${INPUTA}" == "y" ]]; then
$ORACLE_HOME/bin/sqlplus -s "/as sysdba" <<EOF > ${ARCHIVEENABLE}
WHENEVER SQLERROR EXIT SQL.SQLCODE
shutdown immediate;
startup mount;
alter database archivelog;
alter database open;
exit SQL.SQLCODE
EOF
			if [ $? -ne 0 ]; then
				UpdateLog "Warning: Failed setting database to Archivelog. Error: `grep ORA- ${ARCHIVEENABLE} | head -1` Please refer to: ${ARCHIVEENABLE}"; 
			else
				UpdateLog "Archivelog Mode is turned on."
			fi
		fi
	else
		UpdateLog "Database [${ORACLE_SID}] in Archivelog Mode."
	fi

        if [ `grep -c ":YES" ${FALOG}` -ne 1 ]; then
                UpdateLog "Warning: FLASHBACK STATUS: OFF"
                read -p "`date` Do you want to enable flashback? [Y/N]  " INPUTB
		if [[ "${INPUTB}" == "Y" || "${INPUTB}" == "y" ]]; then
$ORACLE_HOME/bin/sqlplus -s "/as sysdba" <<EOF > ${FLASHENABLE}
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database flashback on;
exit SQL.SQLCODE
EOF
                        if [ $? -ne 0 ]; then
                                UpdateLog "Warning: Failed to enable flashback. Error: `grep ORA- ${FLASHENABLE} | head -1` Please refer to: ${FLASHENABLE}";
                        else
                                UpdateLog "Flashback is turned on."
				echo "`date`" > ${FAFLAG}
                        fi
		fi
	else
		UpdateLog "Flashback is turned On."
		echo "`date`" > ${FAFLAG}
        fi
fi

