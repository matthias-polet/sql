/*** To script an existing SQL Job. Replacing the current @@ServerName with a placeholder. ***/

USE msdb
GO

-- Create FUNCTION to convert the SQL server to a placeholder and vise versa.
CREATE OR ALTER FUNCTION dbo.udf_replace_sql_servername_to_placeholder (@COMMAND NVARCHAR(max))
RETURNS NVARCHAR(max)
WITH EXECUTE AS CALLER
AS
BEGIN
    return replace(@COMMAND, @@SERVERNAME, '<<<SQL_SERVERNAME>>>')
END;
GO

CREATE OR ALTER FUNCTION dbo.udf_replace_placeholder_to_sql_servername (@COMMAND NVARCHAR(max))
RETURNS NVARCHAR(max)
WITH EXECUTE AS CALLER
AS
BEGIN
    RETURN replace(@COMMAND, '<<<SQL_SERVERNAME>>>', @@SERVERNAME)
END;
GO

-- Create PROCEDURE that creates another PROCEDURE to create or alter an SQL Job.
CREATE OR ALTER PROCEDURE dbo.usp_script_sql_job_procedure(@job_name sysname)
AS
BEGIN

IF NOT EXISTS (SELECT * FROM sysjobs WHERE name = @job_name )
BEGIN
    RAISERROR('ERROR: SQL Job does not exist.', 0,1)
    RETURN
END

DROP TABLE IF EXISTS #sql_statement;

SET NOCOUNT ON

CREATE TABLE #sql_statement (
    row_id INT IDENTITY(1, 1), 
    sql_statement NVARCHAR(max)
);

insert into #sql_statement (sql_statement) values ( 'CREATE OR ALTER PROCEDURE dbo.usp_create_or_alter_sql_job_' + @job_name )
insert into #sql_statement (sql_statement) values ( 'AS' )
insert into #sql_statement (sql_statement) values ( 'BEGIN' )
insert into #sql_statement (sql_statement) values ( 'DECLARE @job_id BINARY(16)' )
insert into #sql_statement (sql_statement) values ( 'DECLARE @command NVARCHAR(MAX)' )
insert into #sql_statement (sql_statement) values ( 'SET @job_id = (SELECT job_id FROM sysjobs j WHERE j.name = ''' + @job_name + ''' )' )
insert into #sql_statement (sql_statement) values ( 'IF @job_id IS NULL' )
insert into #sql_statement (sql_statement) values ( 'BEGIN' )
insert into #sql_statement (sql_statement)
select 'EXEC msdb.dbo.sp_add_job @job_name=N''' + j.name + ''', @enabled=1, @owner_login_name=N''' + l.loginname + ''', @job_id = @job_id OUTPUT' as sql
    from sysjobs j
        join sys.syslogins l
            on l.sid = j.owner_sid
    where j.name = @job_name
insert into #sql_statement (sql_statement)
select N'SET @command=dbo.udf_replace_placeholder_to_sql_servername(''' + dbo.udf_replace_sql_servername_to_placeholder(command) + '''); EXEC msdb.dbo.sp_add_jobstep @job_id=@job_id' + ', @step_name=N''' + s.step_name + N'''' + ', @step_id=N'''
       + convert(sysname, s.step_id) + '''' + ', @on_success_action=N''' + convert(sysname, s.on_success_action) + ''''
       + ', @on_success_step_id=N''' + convert(sysname, s.on_success_step_id) + '''' + ', @on_fail_action=N'''
       + convert(sysname, s.on_fail_action) + '''' + ', @on_fail_step_id=N''' + convert(sysname, s.on_fail_step_id)
       + '''' + ', @command=@command'
from sysjobs j
    join sysjobsteps s
        on j.job_id = s.job_id
    join sys.syslogins l
        on l.sid = j.owner_sid
where j.name = @job_name
order by step_id asc
insert into #sql_statement (sql_statement) values ( 'END' )
insert into #sql_statement (sql_statement) values ( 'ELSE' )
insert into #sql_statement (sql_statement) values ( 'BEGIN' )
insert into #sql_statement (sql_statement)
select N'SET @command=dbo.udf_replace_placeholder_to_sql_servername(''' + dbo.udf_replace_sql_servername_to_placeholder(command) + '''); EXEC msdb.dbo.sp_update_jobstep @job_id=@job_id' + ', @step_name=N''' + s.step_name + N'''' + ', @step_id=N'''
    + convert(sysname, s.step_id) + '''' + ', @on_success_action=N''' + convert(sysname, s.on_success_action) + ''''
    + ', @on_success_step_id=N''' + convert(sysname, s.on_success_step_id) + '''' + ', @on_fail_action=N'''
    + convert(sysname, s.on_fail_action) + '''' + ', @on_fail_step_id=N''' + convert(sysname, s.on_fail_step_id)
    + ''''
from sysjobs j
    join sysjobsteps s
        on j.job_id = s.job_id
    join sys.syslogins l
        on l.sid = j.owner_sid
where j.name = @job_name
order by step_id asc
insert into #sql_statement (sql_statement) values ( 'END' )
insert into #sql_statement (sql_statement) values ( 'END' )


declare @sql NVARCHAR(max) = ''
select @sql = @sql + CHAR(13) + CHAR(10) + sql_statement from #sql_statement order by row_id asc
-- Create the actual PROCEDURE.
EXEC sp_executesql @sql
END
GO

-- Usage:
exec dbo.usp_script_sql_job_procedure 'MY_JOB_NAME'
-- And now run the created PROCEDURE to create or alter the SQL job.
-- exec dbo.usp_create_or_alter_sql_job_MY_JOB_NAME
GO

-- Cleanup objects
-- drop function if exists dbo.udf_replace_sql_servername_to_placeholder 
-- GO
-- drop function if exists dbo.udf_replace_placeholder_to_sql_servername
-- go
-- drop procedure if exists dbo.usp_script_sql_job_procedure;
-- go