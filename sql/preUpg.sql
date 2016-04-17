set echo off head off
define logdir=&1
set serveroutput on
Prompt
Prompt ========================================================================================
Prompt STEP 1. Checking Oracle Database Vault Status (TRUE/FALSE)
Prompt
DOC
  select parameter, value from v$option where parameter =  'Oracle Database Vault';
  select * from v$encryption_wallet;

  TO check Database Vault (kzvidv.o) and Label Security (kzlilbac.o) ON or OFF

  Verify  ON :    ar -t $ORACLE_HOME/rdbms/lib/libknlopt.a | grep -E "kzvidv.o|kzlilbac.o"
  Verify OFF :    ar -t $ORACLE_HOME/rdbms/lib/libknlopt.a | grep -E "kzvndv.o|kzlnlbac.o"

  To disable

  cd $ORACLE_HOME/rdbms/lib
  make -f ins_rdbms.mk dv_off ioracle
  make -f ins_rdbms.mk lbac_off ioracle

#

set linesize 200 echo off feed off
col parameter format a25
col value format a10

select rpad(parameter||' : '||value||'  ', 80, '.') ||'[ OK ]' from v$option where parameter = 'Oracle Database Vault';
select rpad('Wallet Status ' ||' : '||status||'  ', 80, '.') ||'[ OK ]' from v$encryption_wallet;

Prompt
Prompt ========================================================================================
Prompt STEP 2. Checking Recyclebin
Prompt
DOC
  select count(*) from dba_recyclebin;
  purge dba_recyclebin;
#

select rpad('Recyclebin Total Objects Count : '||count(*)||'  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end  as  "Recyclebin Total Objects" from dba_recyclebin;

declare
  vObjectCount number;
  vRecycleEmpty number := 0;
begin
  execute immediate 'select count(*) from dba_recyclebin' into vObjectCount;

  if vObjectCount <> 0 then
     vRecycleEmpty := 1;
     dbms_output.put_line('Purging Recyclebin ...');
     execute immediate 'purge dba_recyclebin';
  end if;
  execute immediate 'select count(*) from dba_recyclebin' into vObjectCount;
  if vRecycleEmpty = 1 then
     if vObjectCount = 0 then
        dbms_output.put_line('There are '||vObjectCount||' objects in Recylebin.  .............................................[ RESOLVED ]');
     else
        dbms_output.put_line('There are '||vObjectCount||' objects in Recylebin.  .............................................[ NOT RESOLVED ]');
     end if;
   end if;
end;
/


Prompt
Prompt ========================================================================================
Prompt
Prompt STEP 3. Checking TIMESTAMP WITH TIMEZONE Data type
Prompt
DOC
   select tz_version from registry$database;
#

select rpad('TZ_VERSION : '||TZ_VERSION||'  ', 80, '.')||'[ OK ]' from registry$database;

Prompt
Prompt ========================================================================================
Prompt STEP 4. Verifying NLS_NCHAR_CHARACTERSET is set as AL16UTF16
--select 'Actual Value Set for NLS_NCHAR_CHARACTERSET: AL16UTF16   '||case value when 'AL16UTF16' then 'NO ACTION REQUIRED' else ' ACTION REQUIRED.  Quitting Pre-upgrade Check' end as "VALUE SET" from NLS_DATABASE_PARAMETERS where parameter = 'NLS_NCHAR_CHARACTERSET';
Prompt
DOC
   select value from nls_database_parameters where parameter = 'NLS_NCHAR_CHARACTERSET';
#

select rpad('NLS_NCHAR_CHARACTERSET: '||value||'  ', 80, '.')||case value when 'AL16UTF16' then '[ OK ]' else '[ NOT OK ]' end from NLS_DATABASE_PARAMETERS where parameter = 'NLS_NCHAR_CHARACTERSET';

col group# format 99
col member format a120
set pagesize 50000
Prompt
Prompt ========================================================================================
Prompt STEP 5. List all Controlfiles, Datafiles, Tempfiles, Redo Log Files
select '  ' as blank_line from dual;
exec dbms_output.put_line('Control Files');
exec dbms_output.put_line('------------------------------------------------------------------------------------------');
select name from v$controlfile order by name;
select rpad('Total Number of Controlfiles : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as controlfiles from v$controlfile;
exec dbms_output.put_line('Data Files');
exec dbms_output.put_line('------------------------------------------------------------------------------------------');
select name from v$datafile order by name;
select rpad('Total Number of Data files : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as datafiles from v$datafile;
exec dbms_output.put_line('Temp Files');
exec dbms_output.put_line('------------------------------------------------------------------------------------------');
--select 'Temp Files' || chr(10) || chr(13) || rpad('-', 79, '-') from dual union all select name from v$tempfile order by name;
select name from v$tempfile order by name;
select rpad('Total Number of Temp files : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as tempfiles from v$tempfile;
exec dbms_output.put_line('Redo Log Files');
exec dbms_output.put_line('------------------------------------------------------------------------------------------');
select group#, member from v$logfile order by 1, 2;
select rpad('Total Number of Redo Log files : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as redofiles from v$logfile;

Prompt
Prompt ========================================================================================
Prompt STEP 6. Checking Materialized View Last Refresh
select distinct rpad(trunc(last_refresh) || '   ', 80, '.') || '[ OK ]' as LAST_REFRESH  from dba_snapshot_refresh_times;

Prompt
Prompt ========================================================================================
Prompt STEP 7. Gathering Data Dictionary Stats
Prompt 
DOC
   exec dbms_stats.gather_dictionary_stats;
# 
Prompt 
exec dbms_stats.gather_dictionary_stats;
select rpad('Data Dictionary Stat Gathering - Complete ', 80, '.') || '[ OK ]' as dict_stats from dual;
prompt
prompt

Prompt ========================================================================================
Prompt STEP 8. Create database link
Prompt 
Prompt Qry: 
Prompt 
select 'create '||decode(u.name,'PUBLIC','PUBLIC ') || ' database link ' || decode(u.name,'PUBLIC',null, 'SYS','',u.name||'.')|| l.name||chr(10) ||'   connect to ' || l.userid || ' identified by "'||l.password||'" using '''||l.host||''';' text from sys.link$ l, sys.user$ u where l.owner# = u.user#;
select rpad('Total Number of Database Links : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as dblinks from sys.link$;

Prompt ========================================================================================
Prompt STEP 9. Ensure no files need Media recovery and No files are in backup mode
Prompt 
DOC  
   select count(*) from v$recover_file;
   select count(*) from v$backup where status != 'NOT ACTIVE';
#
Prompt 
select rpad('Total Number of files need Media recovery : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as media_rec from v$recover_file
union all
select rpad('Total Number of files in Backup mode : ' || count(*) || '  ', 80, '.') || '[ OK ]' || chr(10) || chr(13) as back_mode from v$backup where status != 'NOT ACTIVE';



Prompt ========================================================================================
Prompt STEP 10. Invalid Object Status Count
Prompt
DOC
   select owner,object_name,object_type from dba_objects where
      owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN'
      ,'TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP')
      and status='INVALID' order by 1,2;
#
Prompt
select rpad('System Invalid Object count : '||count(*)||'  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end || chr(10) || chr(13) as "Invalid SYS Objects" from dba_objects where
  owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN','TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP','ENV15OIM_OIM')
  and status='INVALID';

Prompt Running utlrp.sql Before getting INVALID object count ...

Prompt
DOC
@?/rdbms/admin/utlrp
#
@?/rdbms/admin/utlrp
Prompt
Prompt   Completed utlrp Run.  Retrieving INVALID object list if any ...
Prompt

declare
  vObjectCount number;
  vSysObjCount number :=0;
begin
  select count(*) into vSysObjCount from dba_objects where owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN'
  ,'TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP') and status='INVALID' ;

  if vSysObjCount <> 0 then
     dbms_output.put_line('System Invalid Object count :   ................................................[ NOT RESOLVED ]');
     dbms_output.put_line(' ');
     dbms_output.put_line('  Quitting PRE-CHECK Upgrade Procedure.   Need manual Intervention !!!!!!!!!!! ');
  end if;

end;
/

col owner format a30
set head on
select owner, object_type, count(*) from dba_objects where status = 'INVALID' group by owner, object_type;
--owner not in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN','TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP')

set head off
select rpad('Total Non-System INVALID object count : ' || count(*) || '  ', 80, '.') || '[ OK ]' as "Non System Object Count" from dba_objects where status='INVALID';

Prompt
Prompt ========================================================================================
Prompt STEP 11. Checking for distributed transaction
Prompt
DOC
   select local_tran_id from dba_2pc_pending;
   execute dbms_transaction.purge_lost_db_entry('local_tran_id');
#

  --spool /tmp/distribute_trans.sql
  spool &logdir/distribute_trans_&&2..&&3..sql
  set pagesize 0 head off feed off
  select 'execute dbms_transaction.purge_lost_db_entry(' || local_tran_id || ''');' from dba_2pc_pending;
  spool off

  --@/tmp/distribute_trans.sql
  @&logdir/distribute_trans_&&2..&&3..sql

prompt

  select rpad('Distributed Transaction Count : ' || count(*) || '  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end as Dist_Count  from dba_2pc_pending;

Prompt
Prompt ========================================================================================
Prompt STEP 12. Checking for Logical Corruption - Analyze object(s)
Prompt
DOC
   select 'analyze cluster "'||cluster_name||'" validate structure cascade;' from dba_clusters where owner = 'SYS'
   union
   select 'analyze table "'||table_name||'" validate structure cascade;' from dba_tables where owner='SYS' and partitioned='NO' and table_name!='FGA_LOG$' and (iot_type='IOT' OR iot_type is NULL)
   union
   select 'analyze table "'||table_name||'" validate structure cascade into invalid_rows;' from dba_tables where owner='SYS' and partitioned='YES';

   select count(*) from invalid_rows;
#


declare
  vObjectCount number := 0;
begin
  select count(*) into vObjectCount from dba_tables where owner = 'SYS' and table_name = 'INVALID_ROWS';
  if vObjectCount = 0 then
     execute immediate 'create table invalid_rows (owner_name varchar2(128), table_name varchar2(128), partition_name varchar2(128), subpartition_name varchar2(128), head_rowid rowid, analyze_timestamp date)';
  end if;
end;
/

  --define logdir=&1

   --spool /tmp/analyze.sql
   spool &logdir/analyze_&&2..&&3..sql
   set pagesize 0 head off feed off
   select 'spool &logdir/analyze.log' || chr(10) || chr(13) || 'set echo on time on timing on feed off' from dual;

   select 'analyze cluster "'||cluster_name||'" validate structure cascade;' from dba_clusters where owner = 'SYS'
   union
   select 'analyze table "'||table_name||'" validate structure cascade;' from dba_tables where owner='SYS' and partitioned='NO' and table_name!='FGA_LOG$' and (iot_type='IOT' OR iot_type is NULL) 
   union
   select 'analyze table "'||table_name||'" validate structure cascade into invalid_rows;' from dba_tables where owner='SYS' and partitioned='YES';

   select ' '|| chr(10) || chr(13) || 'set echo off time off timing off ' || chr(10) || chr(13) || 'spool off' from dual;

   spool off

   --@/tmp/analyze.sql
   @&logdir/analyze_&&2..&&3..sql

Prompt
Prompt
   select rpad('Logical Corruption Count : ' || count(*) || '  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end as Dist_Count  from invalid_rows;
Prompt
Prompt


Prompt ========================================================================================
Prompt STEP 13. Checking for Standby Database Configuration
Prompt
DOC
   select substr(value,instr(value,'=',instr(upper(value),'SERVICE'))+1) from
      v$parameter where name like 'log_archive_dest%' AND UPPER(value) LIKE 'SERVICE%';
#

Prompt
   select rpad('Standby Database Configuration : ' || case count(*) when 0 then ' Not Exists.' else ' Exists.' end || '  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ OK ]' end as standby_config from v$parameter where name like 'log_archive_dest%' AND UPPER(value) LIKE 'SERVICE%';

Prompt
Prompt


Prompt ========================================================================================
Prompt STEP 14. Checking just AUD$ count to estimate the delay.  No action by Automation Script
Prompt
DOC
   select count(*) from aud$;
   select owner, table_name from dba_tables where table_name = 'AUD$';
#

Prompt
   select rpad('AUD$ Row Count : ' || count(*) || '  ', 80, '.') || '[ OK ]' from aud$;
   select rpad('AUD$ owned by : ' || owner || '  ', 80, '.') || case owner when 'SYS' then '[ OK ]' else '[ NOT OK ]' end as status from dba_tables where table_name = 'AUD$' and owner in ('SYS', 'SYSTEM');

Prompt
Prompt



Prompt ========================================================================================
Prompt STEP 15. Checking SYS, SYSTEM users default tablespace
Prompt
DOC
   select username, default_tablespace from dba_users where username in ('SYS', 'SYSTEM');
   alter user SYS default tablespace SYSTEM;
   alter user SYSTEM default tablespace SYSTEM;

#

Prompt

col username format a10
col default_tablespace format a30
col status format a40
set linesize 200 head on

select username, default_tablespace, lpad(case default_tablespace when 'SYSTEM' then '[ OK ]' else '[ NOT OK ]' end, 40, '.') status from dba_users where username in ('SYS', 'SYSTEM');


Prompt
Prompt ========================================================================================
Prompt STEP 16. Checking Oracle Components
Prompt
DOC
  col comp_id format a15
  col comp_name format a40
  col version format a15
  col status format a15
  set linesize 120 pagesize 50
  select comp_id, comp_name, version, status from dba_registry;
#

  set linesize 200 echo off feed off head on

  col comp_id format a10
  col comp_name format a40
  col version format a15
  col status format a15
  set linesize 120 pagesize 50
  select comp_id, comp_name, version, status from dba_registry;
  set head off
select rpad('Overall Component Status  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end as "Component Status"  from dba_registry where status = 'INVALID';

Prompt
Prompt ========================================================================================
Prompt STEP 17. Proactive Check - Useful for Parameter Comparision or Status Check
Prompt
DOC
   col name format a32
   col value format a80
   set linesize 200 pagesize 50
   select name, value from v$parameter;
#

col name format a32
col value format a120
set linesize 200 pagesize 50 head on
select name, value from v$parameter where name in ('audit_file_dest' ,'audit_trail' ,'background_core_dump' ,'background_dump_dest' ,'buffer_pool_keep' ,'buffer_pool_recycle' ,'cluster_database' ,'compatible' ,'core_dump_dest' ,'db_create_file_dest' ,'db_create_online_log_dest_1' ,'db_create_online_log_dest_2' ,'db_create_online_log_dest_3' ,'db_file_name_convert' ,'db_files' ,'db_name' ,'db_recovery_file_dest' ,'db_recovery_file_dest_size' ,'db_unique_name' ,'instance_name' ,'job_queue_processes' ,'log_archive_config' ,'log_archive_dest' ,'log_archive_dest_1' ,'log_archive_dest_2' ,'log_archive_dest_3' ,'log_archive_dest_4' ,'log_archive_format' ,'log_file_name_convert' ,'memory_max_target' ,'memory_target' ,'open_cursors' ,'pga_aggregate_target' ,'processes' ,'recyclebin' ,'sessions' ,'sga_max_size' ,'sga_target' ,'spfile' ,'statistics_level' ,'undo_management' ,'undo_retention' ,'undo_tablespace' ,'user_dump_dest') order by 1;
set head off
Prompt
Prompt
Prompt

exit
