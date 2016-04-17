#########################################################################
# Title: 11g_Env.sh 
# Purpose: Set the 11g Environment
#
# Created: MSH
##########################################################################


export ORACLE_UNQNAME=${ORACLE_SID}
export ORACLE_HOME=${OLD_ORA_HOME}

PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
