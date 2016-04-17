
set echo off head off
set serveroutput on
Prompt
Prompt ========================================================================================
Prompt STEP 1. Checking Oracle Database Vault Status (TRUE/FALSE)
Prompt
DOC
  select parameter, value from v$option where parameter =  'Oracle Database Vault';
  select * from v$encryption_wallet;
#

set linesize 200 echo off feed off
col parameter format a25
col value format a10

select rpad(parameter||' : '||value||'  ', 80, '.') ||'[ OK ]' from v$option where parameter = 'Oracle Database Vault';
select rpad('Wallet Status ' ||' : '||status||'  ', 80, '.') ||'[ OK ]' from v$encryption_wallet;

Prompt
Prompt ========================================================================================
Prompt
Prompt STEP 2. Checking TIMESTAMP WITH TIMEZONE Data type
Prompt
DOC
   select tz_version from registry$database;
#

select rpad('TZ_VERSION : '||TZ_VERSION||'  ', 80, '.')||'[ OK ]' from registry$database;
Prompt
Prompt ========================================================================================
Prompt STEP 3. Checking SYS, SYSTEM users default tablespace
Prompt
DOC
   select username, default_tablespace from dba_users where username in ('SYS', 'SYSTEM');
   alter user SYS default tablespace SYSTEM;
   alter user SYSTEM default tablespace SYSTEM;

#
col username format a10
col default_tablespace format a30
col status format a40
set linesize 200 head on
select username, default_tablespace, lpad(case default_tablespace when 'SYSTEM' then '[ OK ]' else '[ NOT OK ]' end, 40, '.') status from dba_users where username in ('SYS', 'SYSTEM');
set head off
Prompt
col group# format 99
col member format a120
set pagesize 50000
Prompt
Prompt ========================================================================================
Prompt STEP 4. List all Controlfiles, Datafiles, Tempfiles, Redo Log Files
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
Prompt STEP 5. Checking just AUD$ count to estimate the delay.  No action by Automation Script
Prompt
DOC
   select count(*) from aud$;
   select owner, table_name from dba_tables where table_name = 'AUD$';
#

set linesize 200
Prompt
   select rpad('AUD$ Row Count : ' || count(*) || '  ', 80, '.') || '[ OK ]' from aud$;
   select rpad('AUD$ owned by : ' || owner || '  ', 80, '.') || case owner when 'SYS' then '[ OK ]' else '[ NOT OK ]' end as status from dba_tables where table_name = 'AUD$' and owner in ('SYS', 'SYSTEM');

Prompt
Prompt ========================================================================================
Prompt STEP 6. Invalid Object Status Count
Prompt
Prompt Running utlrp.sql Before getting INVALID object count ...
Prompt
DOC
   @?/rdbms/admin/utlrp

   select owner,object_name,object_type from dba_objects where
      owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN'
      ,'TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP')
      and status='INVALID' order by 1,2;
#
#
@?/rdbms/admin/utlrp
Prompt
Prompt   Completed utlrp Run.  Retrieving INVALID object list if any ...
Prompt
Prompt
select rpad('System Invalid Object count : '||count(*)||'  ', 80, '.') || case count(*) when 0 then '[ OK ]' else '[ NOT OK ]' end || chr(10) || chr(13) as "Invalid SYS Objects" from dba_objects where
  owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN','TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP','ENV15OIM_OIM')
  and status='INVALID';

declare
  vObjectCount number;
  vSysObjCount number :=0;
begin
  select count(*) into vSysObjCount from dba_objects where owner in ('SYSMAN','CTXSYS','ORDSYS','MDSYS','EXFSYS','WKSYS','WKPROXY','WK_TEST','OLAPSYS','OUTLIN'
  ,'TSMSYS','FLOWS_FILES','SI_INFORMTN_SCHEMA','ORACLE_OCM','ORDPLUGINS','ORDDATA','DBSNMP') and status='INVALID' ;

  if vSysObjCount <> 0 then
     dbms_output.put_line('System Invalid Object count :   ................................................[ NOT RESOLVED ]');
     dbms_output.put_line(' ');
     dbms_output.put_line('  Quitting POST-CHECK Upgrade Procedure.   Need manual Intervention !!!!!!!!!!! ');
  end if;

 if vSysObjCount = 0 then 
     dbms_output.put_line('System Invalid Object count :   ................................................[ RESOLVED ]');
     dbms_output.put_line(' ');
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
Prompt STEP 7. Checking Oracle Components
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
Prompt STEP 8. Proactive Check - Useful for Parameter Comparision or Status Check
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

#exit

