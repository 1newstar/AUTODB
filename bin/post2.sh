#!/bin/bash
##########################################################################
# Title: post2.sh
# Purpose: Drop restore point before 12c upgrade and set compatibility to 12.1.0
#
# Details: If flashback is not on dropping of restore point will be skipped
# Note: This is the point of no return, you will be unable to restore your database back to 11g
#
# Created: 
##########################################################################
. $WKDIR/bin/12c_Env.sh

export LOGDIR=$WKDIR/logs/${ORACLE_SID}
export ORACLE_SID=`grep ORACLE_SID $PARFILE  | awk -F"=" '{print $2}'`
export ORACLE_HOME=`grep NEW_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`
export TNS_ADMIN=$ORACLE_HOME/network/admin
DT=`date +%Y-%m-%d`
export UNQNAME=$ORACLE_SID

#added error handiling
#HZ provide error description or number upon exit
#Check if restore point exists before dropping, if does not exist then continue
CHECKRP=$LOGDIR/post/post2_${ORACLE_SID}_${DT}_check.log
${ORACLE_HOME}/bin/sqlplus -s -l '/ as sysdba' <<EOF > ${CHECKRP}
WHENEVER SQLERROR EXIT SQL.SQLCODE
select NAME from v\$restore_point where NAME='BEFORE_12C_UPGRADE';
exit sql.sqlcode
EOF
if [ $? -ne 0 ]; then
	echo "`date` post2.sh failed. Error: `grep ORA- ${CHECKRP} | head -1`"
fi

if [ `grep -c BEFORE_12C_UPGRADE ${CHECKRP}` -eq 1 ]; then
	echo "`date` Restore Point: before_12c_upgrade found"
else
	echo "`date` Restore Point: before_12c_upgrade not found."
fi
DROPRESTORE=""
if [ -f ${FAFLAG} ]; then
	DROPRESTORE="drop restore point before_12c_upgrade;"
#	echo "Uncomment this one to proceed with drop restore point"
fi

#HZ Do not exit script if restore point cannot be dropped, display error and continue to the next step
DROPPR=$LOGDIR/post/post2${ORACLE_SID}_${DT}.log
${ORACLE_HOME}/bin/sqlplus -s -l  '/ as sysdba' << EOF1 > ${DROPPR}
WHENEVER SQLERROR EXIT SQL.SQLCODE
${DROPRESTORE}
set lines 200
set pages 200
set head off
select * from gV\$restore_point;
exit sql.sqlcode
EOF1
if [ $? -ne 0 ]; then
   echo "`date` post2.sh failed. Error: `grep ORA- ${DROPPR} | head -1`"
   rm ${OPTION3} > /dev/null
   exit 1
else
	 if [ `echo ${DROPRESTORE} | grep -c drop` -eq 1 ]; then

                echo "`date` Restore Point: before_12c_upgrade dropped."
        else
                echo "`date` Dropping of restore point skipped. Archivelog or Flashback is turned off."
        fi
fi
SETCOMP=$LOGDIR/post/post2${ORACLE_SID}compatible_${DT}.log
${ORACLE_HOME}/bin/sqlplus -s -l '/ as sysdba' << EOF2 > ${SETCOMP}
WHENVER SQLERROR EXIT SQL.SQLCODE
alter system set compatible='12.1.0' scope=spfile sid='*';
set lines 200
set pages 200
set head off
exit sql.sqlcode
EOF2
if [ $? -ne 0 ]; then
                echo "`date` post2.sh failed. Error: `grep ORA- ${SETCOMP} | head -1`"
                rm ${OPTION1} > /dev/null
                exit 1
	else
		echo "`date` Compatability set to 12.1.0 successfully.." 
fi
