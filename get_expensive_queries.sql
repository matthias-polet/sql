use master -- Change to any database you want to deploy on.
GO

create or alter PROCEDURE dbo.usp_insert_expensive_queries 
AS
begin
declare @datetime datetime
DECLARE @currenttime varchar(30);

if not exists (select * from sys.tables where name = 'expensive_queries')
BEGIN
	SET @datetime = getdate();
	set @currenttime = FORMAT(@datetime,'o');;
	RAISERROR('%s - The table expensive_queries does not exist, so we create it now.', 0, 1, @currenttime) WITH NOWAIT;
	SELECT TOP(100) 
	@datetime as DateTime,
	db_name() as DatabaseName,
	qs.execution_count AS [ExecutionCount],
	(qs.total_logical_reads)*8/1024.0 AS [TotalLogicalReads_MB],
	(qs.total_logical_reads/qs.execution_count)*8/1024.0 AS [Avg Logical Reads_MB],
	(qs.total_worker_time)/1000.0 AS [TotalWorkerTime_ms],
	((qs.total_worker_time)/1000000.0)/60/60 AS [TotalWorkerTime_h],
	(qs.total_worker_time/qs.execution_count)/1000.0 AS [AvgWorkerTime_ms],
	(qs.total_elapsed_time)/1000.0 AS [TotalElapsedTime_ms],
	(qs.total_elapsed_time/qs.execution_count)/1000.0 AS [AvgElapsedTime_ms],
	qs.creation_time AS [CreationTime]
	,t.text AS [Complete Query Text], qp.query_plan AS [QueryPlan]
	into dbo.expensive_queries
	FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
	CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
	where 1 = 2
end

SET @datetime = getdate();
set @currenttime = FORMAT(@datetime,'o');
RAISERROR('%s - Insert Expensive Queries', 0, 1, @currenttime) WITH NOWAIT;


insert into dbo.expensive_queries
SELECT TOP(100) 
	@datetime as DateTime,
	db_name() as DatabaseName,
	qs.execution_count AS [ExecutionCount],
	(qs.total_logical_reads)*8/1024.0 AS [TotalLogicalReads_MB],
	(qs.total_logical_reads/qs.execution_count)*8/1024.0 AS [Avg Logical Reads_MB],
	(qs.total_worker_time)/1000.0 AS [TotalWorkerTime_ms],
	((qs.total_worker_time)/1000000.0)/60/60 AS [TotalWorkerTime_h],
	(qs.total_worker_time/qs.execution_count)/1000.0 AS [AvgWorkerTime_ms],
	(qs.total_elapsed_time)/1000.0 AS [TotalElapsedTime_ms],
	(qs.total_elapsed_time/qs.execution_count)/1000.0 AS [AvgElapsedTime_ms],
	qs.creation_time AS [CreationTime]
	,t.text AS [Complete Query Text], qp.query_plan AS [QueryPlan]
	FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
	CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
	WHERE t.dbid = DB_ID()
	ORDER BY [TotalWorkerTime_h] DESC OPTION (RECOMPILE);
	
end
GO

create or alter PROCEDURE dbo.usp_get_expensive_queries 
AS
begin
	EXEC dbo.usp_insert_expensive_queries;
	select * from dbo.expensive_queries;
end
GO

-- Usage:
-- Run to get the expensive queries
-- stores the result in dbo.expensive_queries, so even if the CACHE clears you still have the result
-- Stores up to 100 queries
exec dbo.usp_get_expensive_queries 