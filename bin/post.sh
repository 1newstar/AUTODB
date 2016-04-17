#!/bin/bash
#########################################################################################################
# Title: post.sh
# Purpose: To automate the 12c Upgrade Process
# Author : Sharad Pendkar
#
# Modified On      Who               Purpose
# --------------   ----------------  -------------------------------------------------------------------
# 12-MAR-2015      Sharad Pendkar    Initial Version
# 05-AUG-2015      Huzaifa Zainuddin Call variables from PARFILE
#########################################################################################################
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

usage ()
{
  echo "Usage : $0 someone@domain.com"
  rm ${OPTION3} > /dev/null
  exit 1
}
# Set 12c environment
. $WKDIR/bin/12c_Env.sh

ORA_SID=`grep "ORACLE_SID=" ${PARFILE}  | awk -F"=" '{print $2}'`
MAILID=`grep "MAILID=" ${PARFILE}  | awk -F"=" '{print $2}'`

#MB For the case statement, we might encounter some errors:
#1. Need to check if first parameter is an existing SID and second parameter is an email

if [ `uname -a | grep -c Linux` -ne 0 ]; then
        ORATAB=/etc/oratab
else
        ORATAB=/var/opt/oracle/oratab
fi

if [ `grep -c ${ORACLE_SID} ${ORATAB}` -eq 0 ]; then
        echo "ORACLE_SID not found in oratab"
	rm ${OPTION3} > /dev/null
        exit 1
fi

HOSTNAME=`hostname`
TIMESTAMP=`date +%Y%m%d_%H%M%S`
ORATAB=/etc/oratab
OLD_ORA_HOME=`grep OLD_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`
NEW_ORA_HOME=`grep NEW_ORA_HOME $PARFILE  | awk -F"=" '{print $2}'`
LOGDIR=$WKDIR/logs/${ORA_SID}
#MB Needs to check if directory is existing
check_directory ${LOGDIR}

#-----------------------------------------------------------------
#Other variables leaving untouched no need to include in PARFILE
#-----------------------------------------------------------------
PFILE=${LOGDIR}/init${ORA_SID}.ora.${TIMESTAMP}

SRC_TNSNAMES=${OLD_ORA_HOME}/network/admin/tnsnames.ora
SRC_LISTENER=${OLD_ORA_HOME}/network/admin/listener.ora
SRC_SQLNET=${OLD_ORA_HOME}/network/admin/sqlnet.ora
SRC_PWD_FILE=${OLD_ORA_HOME}/dbs/orapwd${ORA_SID}
DEST_TNPSNAMES=${LOGDIR}/tnsnames.ora
DEST_LISTENER=${LOGDIR}/listener.ora
DEST_SQLNET=${LOGDIR}/sqlnet.ora
DEST_PWD_FILE=${LOGDIR}/orapwd${ORA_SID}
BACKUP_ORATAB=$LOGDIR/${HOSTNAME}.${ORA_SID}.oratab.$TIMESTAMP
ACTIVITY_LOG=${LOGDIR}/post/${HOSTNAME}.${ORA_SID}.activity.${TIMESTAMP}.log
ACTIVITY_TMP_LOG=${LOGDIR}/post/${HOSTNAME}.${ORA_SID}.tmp.${TIMESTAMP}.log
SUBJECT="AutoUpgrade"
 UpdateLog ()
{
   msg="$1"
   echo "$msg" | tee -a $ACTIVITY_LOG
}

ExitAutoUpgrade()
{
   echo " "
   echo "        !!!!!!!!!!   $1 Upgrade check FAILED  !!!!!!!!!!  Please take corrective action."
   echo " "
   rm ${OPTION3} > /dev/null
   exit 1;
}

[ ! -d ${LOGDIR} ] && mkdir -p ${LOGDIR}

if [ ! -d ${LOGDIR} ]; then
   echo ""
   echo ""
   echo " Log Directory ${LOGDIR} does not exists!."
   echo ""
   echo ""
   rm ${OPTION3} > /dev/null
   exit 1
fi

UpdateLog " "
UpdateLog " "
clear
UpdateLog "============================================================================== "
UpdateLog " "
UpdateLog "       HOSTNAME : ${HOSTNAME}"
UpdateLog "     Oracle SID : $ORA_SID"
UpdateLog "New Oracle Home : ${NEW_ORA_HOME}"
UpdateLog "        Log Dir : $LOGDIR"
UpdateLog "   Activity Log : $ACTIVITY_LOG"
UpdateLog "        Mail ID : $MAILID"
UpdateLog "         OPTION : Post-Check"
UpdateLog " "
UpdateLog "============================================================================== "
UpdateLog " "
while true
do
   echo "Please confirm above inputs (Y/N) : "
   read ans
   case $ans in
     n|N)
	 rm ${OPTION3} > /dev/null
         exit 1
         ;;
     y|Y)
         break
         ;;
   esac
done

echo "Please confirm above inputs (Y/N) : " >> $ACTIVITY_LOG
UpdateLog "Your answer : $ans"

UpdateLog " "
UpdateLog " "
UpdateLog "Validating Input Values..."
UpdateLog " "

if [ `cat $ORATAB | grep -v "^#" | grep "$ORA_SID" | wc -l` -ge 2 ]; then
   UpdateLog "Duplicate entry in $ORATAB file.  Needs manual intervention to correct it.  Quitting AutoUpgrade Script !!!!!!!!!!"
   ExitAutoUpgrade "INVALID Input"
elif [ `cat $ORATAB | grep -v "^#" | grep "$ORA_SID" | wc -l` -eq 1 ]; then
   OLD_ORA_HOME=`cat $ORATAB | grep -v "^#" | grep "$ORA_SID" | cut -d":" -f2`
else
   OLD_ORA_HOME=`cat $ORATAB | grep "^###AutoUpgradeScript###" | grep "$ORA_SID" | cut -d":" -f2`
   if [ -z "$OLD_ORA_HOME" ]; then
      UpdateLog "Old Oracle Home does not exists in $ORATAB file.  Quitting AutoUpgrade Script !!!!!!!!!!"
      ExitAutoUpgrade "INVALID Input"
   fi
fi

if [ ! -d "$NEW_ORA_HOME" ]; then
    UpdateLog "New Oracle home does not exists.  Quitting AutoUpgrade Script !!!!!!!!!!"
    rm ${OPTION3} > /dev/null
    exit 1
fi

export ORACLE_SID=$ORA_SID
export ORACLE_HOME=$NEW_ORA_HOME

export ORACLE_UNQNAME=${ORACLE_SID}
echo $ORACLE_UNQNAME
UpdateLog "Checking DB Connectivity with New Oracle Home ..."
UpdateLog " "

DB_STATUS=`$ORACLE_HOME/bin/sqlplus -s ' / as sysdba'<< EOF
   set head off
   select open_mode from v\\$database;
EOF`

if [ `echo $DB_STATUS | grep "READ WRITE" | wc -l` -eq 0 ]; then
   UpdateLog "Database ${ORA_SID} is not Open.  Please Startup the database."   
   ExitAutoUpgrade " "
fi


UpdateLog " "
UpdateLog " "
UpdateLog "Input Values Validated by AutoUpgrade Script on `date` "
UpdateLog " "
UpdateLog " "
UpdateLog "------------------------------------------------------------------------------------------"
UpdateLog "Activity Log File: $ACTIVITY_LOG "
UpdateLog "------------------------------------------------------------------------------------------"
UpdateLog " "

#MB Added error handling
#HZ script is exiting with condition set, need to identify where error is coming from
$ORACLE_HOME/bin/sqlplus "/as sysdba" <<EOF >> $ACTIVITY_TMP_LOG
WHENEVER SQLERROR EXIT SQL.SQLCODE
@${NEW_ORA_HOME}/rdbms/admin/catuppst.sql
@${NEW_ORA_HOME}/rdbms/admin/utlrp.sql
@/u01/app/oracle/cfgtoollogs/$ORACLE_UNQNAME/preupgrade/postupgrade_fixups.sql 
@${NEW_ORA_HOME}/rdbms/admin/utlu121s.sql 
@${NEW_ORA_HOME}/rdbms/admin/utluiobj.sql 
@${WKDIR}/sql/postUpg.sql 
exit sql.sqlcode
EOF
if [ $? -ne 0 ]; then
	echo "`date` post.sh failed. Error: `grep ORA- $ACTIVITY_TMP_LOG | head -1`"; rm ${OPTION3} > /dev/null; exit 1;
fi

cat $ACTIVITY_TMP_LOG >> $ACTIVITY_LOG

cat $ACTIVITY_LOG

UpdateLog " "
UpdateLog "------------------------------------------------------------------------------------------"
UpdateLog "Activity Log File: $ACTIVITY_LOG "
UpdateLog "------------------------------------------------------------------------------------------"
UpdateLog " "
echo
echo

SUBJECT="AutoUpgrade : STATUS : 12c Post Upgrade Verification - ${ORA_SID}@${HOSTNAME}"
if [ `whereis uuencode | cut -d' ' -f2 | grep -c "uuencode$"` -eq 0 ]; then
	echo "Post Upgrade Verification, log located: ${ACTIVITY_LOG} for - ${ORA_SID}@${HOSTNAME} - AutoGenerated by AUTODB" | mailx -s "$SUBJECT" $MAILID
	echo "`date` notification email sent without attachment. uuencode is not installed"
else
	echo "Post Upgrade Verification, Please view attached log file for details - ${ORA_SID}@${HOSTNAME} - AutoGenerated by AUTODB" | mailx -s "$SUBJECT" -a $ACTIVITY_LOG $MAILID
fi



