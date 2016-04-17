#!/bin/bash
#########################################################################
# Title: AUTODB.sh
# Purpose: Main driver script which automates database upgrade into three stages for pre post and upgrade.
# 
#
# 
# Created by: Huzaifa. Zainuddin
##########################################################################
export PROCESSID=$$
clear
echo "#####################################################################################"
echo "			Accenture Upgrade Toolkit for Oracle Database AUTODB"
echo ""
echo ""
echo "This script automates  preupgrade, upgrade, and post upgrade tasks required by Oracle"
echo "Please view the README file for more detail on what each script does"
echo "Note: Make sure DB is in archivelog mode to enable flashback recovery"
echo ""
echo "-------------------------------------------------------------------------------------"
if [ $# -ne 1 ]; then
	echo "`date` Wrong number of arguments. Syntax $0 <ORACLE_SID>"
	exit 1
fi

if [ `uname -a | grep -c Linux` -ne 0 ]; then
        ORATAB=/etc/oratab
else
        ORATAB=/var/opt/oracle/oratab
fi

export ORACLE_SID=$1
export WKDIR=$PWD
export PARFILE=${WKDIR}/config/param_${ORACLE_SID}.txt
export FAFLAG=${WKDIR}/.flasharchive_${ORACLE_SID}
export LOGDIR=$WKDIR/logs/${ORACLE_SID}

if [ `cat ${ORATAB} | grep "${ORACLE_SID}:" | grep -v "#" | wc -l` -eq 0 ]; then
        echo "`date` ORACLE_SID not found in oratab"; exit 1;
fi

if [ ! -d ${WKDIR} ]; then
        echo "`date` Working Directory [${WKDIR}] not existing."; exit 1;
fi

# OLD_ORA_HOME grepped from ORATAB
export OLD_ORA_HOME=`cat ${ORATAB} | grep "${ORACLE_SID}:" | grep -v "#" | head -1 | cut -d':' -f2`
if [ -f ${PARFILE} ]; then
	export OLD_ORA_HOME=`grep OLD_ORA_HOME ${PARFILE} | cut -d'=' -f2`
	export NEW_ORA_HOME=`grep NEW_ORA_HOME ${PARFILE} | cut -d'=' -f2`
fi

echo ""

while true; do
#clear
export OPTION0=${WKDIR}/.steps_${ORACLE_SID}_0
export OPTION1=${WKDIR}/.steps_${ORACLE_SID}_1
export OPTION2=${WKDIR}/.steps_${ORACLE_SID}_2
export OPTION3=${WKDIR}/.steps_${ORACLE_SID}_3
export OPTION4=${WKDIR}/.steps_${ORACLE_SID}_4
STATUS00="-----------"
STATUS01="-----------"
STATUS02="-----------"
STATUS03="-----------"

if [ -f ${OPTION0} ]; then STATUS00=`cat ${OPTION0} | cut -d',' -f3`; fi
if [ -f ${OPTION1} ]; then STATUS01=`cat ${OPTION1} | cut -d',' -f3`; fi
if [ -f ${OPTION2} ]; then STATUS02=`cat ${OPTION2} | cut -d',' -f3`; fi
if [ -f ${OPTION3} ]; then STATUS03=`cat ${OPTION3} | cut -d',' -f3`; fi

echo "---------------------------------------------------------------------------"
echo "Current Configuration of Parameter File"
echo ""
echo "DATABASE:     ${ORACLE_SID}"
echo "WORKDIR:      ${WKDIR}"
echo "OLD_ORA_HOME: ${OLD_ORA_HOME}"
echo "NEW_ORA_HOME: ${NEW_ORA_HOME}"
echo "PROCESS ID:   ${PROCESSID}"
echo ""
echo "-----------------------------------------------------------------------------"
echo " Please select from the following options:"
echo ""
echo "        Stage			     Status		 Estimated Time	   "
echo "   ---------------                 --------------- 	----------------   "
echo "[0] Set Configuration File         [ ${STATUS00} ] 	1< min	           "
echo "[1] Pre Upgrade                    [ ${STATUS01} ] 	5-10 mins          "
echo "[2] Upgrade                        [ ${STATUS02} ] 	1 hour 20 mins     "
echo "[3] Post Upgrade                   [ ${STATUS03} ] 	5-10 mins          "
echo "[4] Exit"
echo "-----------------------------------------------------------------------------"
read -p "> " OPTION
case ${OPTION} in
	#Checks to see if option has been run or not, if it has been completed then wont allow to run multiple times.
     0) if [ -f ${OPTION1} ]; then
		if [ `cat ${OPTION0} | grep "${ORACLE_SID}," | grep ",COMPLETE," | wc -l` -eq 1 ]; then
                	echo "`date` Option[0]:'Set Configuration File' for [${ORACLE_SID}] is already complete."; exit 1;
		fi
	fi
	#Checks if flag file for option 2 exists, if so the OPTION 0 is not able to be run		
	if [ ! -f ${OPTION2} ]; then
		rm -f ${OPTION0} > /dev/null
		$WKDIR/bin/setupEnv.sh
		if [ $? -eq 0 ]; then
			export NEW_ORA_HOME=`grep NEW_ORA_HOME ${PARFILE} | cut -d'=' -f2`
        		echo "${ORACLE_SID},${PROCESSID},COMPLETE,`date`" > ${OPTION0}
		else 
			rm -rf ${OPTION0} > /dev/null
		fi
	else
		echo "This option is no loger available for the ORACLE_SID: ${ORACLE_SID}"
	fi
	;;
     1) if [ ! -f ${OPTION2} ]; then
	#Checks if flag file exists for option 1, and greps status for inprogress, Wont allow user to continue. If status is complete, stage can be re-run multiple times
		if [ -f ${OPTION1} ]; then
			if [ `cat ${OPTION1} | grep "${ORACLE_SID}," | grep ",INPROGRESS," | grep -v ",${PROCESSID}," | wc -l` -eq 1 ]; then
				echo "`date` There are other users running the same process. Please check. PROCESSID=`cat ${OPTION1} | cut -d',' -f2`"; exit 1;
			fi
		fi
		#Conditions set to check existance if other options have been run 
		if [ ! -f ${OPTION0} ]; then echo "`date` Warning: Option[0]:'Set Configuration File'. Needs to be run"; exit 1; fi
		if [ -f ${OPTION2} ]; then echo "`date`Unable to re-run. Option[2]:'Upgrade' for ${ORACLE_SID} is already complete."; exit 1; fi
		if [ -f ${OPTION3} ]; then echo "`date`Unable to re-run.  Option[3]:'Post Upgrade' for ${ORACLE_SID} is already complete."; exit 1; fi
		echo "${ORACLE_SID},${PROCESSID},INPROGRESS,`date`" > ${OPTION1}
        	$WKDIR/bin/preUpgrade.sh
        	if [ $? -eq 0 ]; then
			$WKDIR/bin/Run_preupgrade.sh
			if [ $? -eq 0 ]; then
				echo "${ORACLE_SID},${PROCESSID},COMPLETE,`date`" > ${OPTION1}
			fi
		fi
	else
		echo "This option is no longer available for the ORACLE_SID:${ORACLE_SID}"
	fi
	;;
     2) #Checks if option 1 (preupgrade) is in progress
	if [ -f ${OPTION1} ]; then
		if [ `cat ${OPTION1} | grep "${ORACLE_SID}," | grep ",INPROGRESS," | grep -v ",${PROCESSID}," | wc -l` -eq 1 ]; then
                        echo "`date` Unable to start Upgrade while Pre Upgrade is in progress. Please check. PROCESSID=`cat ${OPTION1} | cut -d',' -f2`"; exit 1;
                fi
	fi
	#Checks if option 2 has been completed or is in progress prior to it being ran again
	if [ -f ${OPTION2} ]; then
                if [ `cat ${OPTION2} | grep "${ORACLE_SID}," | grep ",INPROGRESS," | grep -v ",${PROCESSID}," | wc -l` -eq 1 ]; then
                        echo "`date` There are other users running the same process. Please check. PROCESSID=`cat ${OPTION2} | cut -d',' -f2`"; exit 1;
                fi
		if [ `cat ${OPTION2} | grep "${ORACLE_SID}," | grep ",COMPLETE," | wc -l` -eq 1 ]; then
			echo "`date` Option[2]:'Upgrade' for [${ORACLE_SID}] is already complete."; exit 1;
		fi
        fi
	#Checks if option 0 and 1 have been complete before running option 2
	if [[ ! -f ${OPTION0} || ! -f ${OPTION1} ]]; then echo "`date` Warning: Unable to process request. Please run Option[0]:'Set Configuration File' and Option[1]:'Pre-Upgrade' first"; exit 1; fi
	echo "${ORACLE_SID},${PROCESSID},INPROGRESS,`date`" > ${OPTION2}
        $WKDIR/bin/upgrade.sh 
	if [ $? -eq 0  ]; then
		$WKDIR/bin/strtup_Trgt.sh
		$WKDIR/bin/update_oratab.sh
        	echo "${ORACLE_SID},${PROCESSID},COMPLETE,`date`" > ${OPTION2}
	fi
	;;
     3) #Checks if upgrade is in progress before continuing
	if [ -f ${OPTION2} ]; then 
		if [ `cat ${OPTION2} | grep "${ORACLE_SID}," | grep ",INPROGRESS," | grep -v ",${PROCESSID}," | wc -l` -eq 1 ]; then
			echo "`date` Unable to start post-upgrade stage while upgrade is in progress"; exit 1;
		fi
	fi
	#Checks if option 3 has been already completed or is in progress
	if [ -f ${OPTION3} ]; then
                if [ `cat ${OPTION3} | grep "${ORACLE_SID}," | grep ",INPROGRESS," | grep -v ",${PROCESSID}," | wc -l` -eq 1 ]; then
                        echo "`date` There are other users running the same process. Please check. PROCESSID=`cat ${OPTION3} | cut -d',' -f2`"; exit 1;
                fi
                if [ `cat ${OPTION3} | grep "${ORACLE_SID}," | grep ",COMPLETE," | wc -l` -eq 1 ]; then
                        echo "`date` Option[3]:'Post Upgrade' for [${ORACLE_SID}] is already complete."; exit 1;
                fi
        fi
	#Checks if option 0,1,2 have all been run before running option 3
	if [[ ! -f ${OPTION0} || ! -f ${OPTION1} || ! -f ${OPTION2} ]]; then
                echo "`date` Warning: Unable to process request. Please run Option[0]:'Set Configuration File', Option[1]:'Pre-Upgrade', and Option[2]:'Upgrade' first";exit 1;
	fi
	echo "${ORACLE_SID},${PROCESSID},INPROGRESS,`date`" > ${OPTION3}
	$WKDIR/bin/post.sh
        if [ $? -eq 0 ]; then
		$WKDIR/bin/post2.sh
        	if [ $? -eq 0 ]; then
			$WKDIR/bin/post3.sh
      			echo "${ORACLE_SID},${PROCESSID},COMPLETE,`date`" > ${OPTION3}
		fi
	fi
	;;
     4) echo "`date` Now Exiting."
	break;
	;;
     *) echo "`date` invalid input"
	;;
esac
done
echo "`date` End of $0"
