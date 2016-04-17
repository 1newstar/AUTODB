###############################################################
# README.txt
#
# Overview of the automated steps of the AUTODB utility
# 
#
#
# Edited 8/24/15 Huzaifa. Z
###############################################################

Execute AUTODB.sh <ORACLE_SID>		

NOTE: It is highly recommended to run this utility in screen session.

Four options will be presented. It is crucial that all stages are run in
sequence. Or the script will present an error

****There is no need to call any of the following scripts independently**** 
This README is to provide a general overview of what script each OPTION calls:



##OPTION 0##

1. setupEnv.sh	         		--> Creates config/param_$ORACLE_SID.txt which holds all variables required for the script

##OPTION 1 - PREUPGRADE SCRIPTS###

2. preUpgrade.sh     			--> Runs preupg.sql, copies oracle preupgd.sql, tnsnames, orapwd,listner from NEW_ORA_HOME to OLD_ORA_HOME 
3. Run_preupgrade.sh 			--> Runs preupgd.sql

##OPTION 2 - UPGRADE SCRIPTS##

4. enablearchiveflash.sh		--> Checks if database is in archive log and flashback. Prompts user to enable archive and flashabck 
5. before_upg_restorepnt.sh             --> Creates Restore Point before upgrade
6. shtdwnSrc.sh                         --> Shutdown db before upgrade 
7. upgrade.sh				--> Starts db in startup upgrade, runs catctl.perl
8. strtup_Trgt.sh			--> Starts database after upgrade
9. update_oratab.sh			--> Updates oratab with new Oracle Home entry and comments the old entry

##OPTION 3 - POST UPGRADE SCRIPTS##

10. post.sh				--> Runs postupgrade_fixups.sql, utlu121s.sql, utluiobjs.sql
11. post2.sh 				--> Set 12c compatability and drops before upgrade restore point
12. post3.sh				--> bounces db, creates restore point after upgrade
##OPTION 4##

Exits the wrapper_script


