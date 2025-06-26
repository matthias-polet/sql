use SSISDB
go

-- Get the duration (eleapsed time) of leaf executions, A leaf execution is an execution without any children.
-- This can be used as input to report the performance of an SSIS package.

drop table if exists #run_time;

;with
	raw_messages (event_message_id, message_time
     , package_name	 
	 , message_source_name
	 , elapsed_time
	 , execution_path
	 , depth
	 , parent)
	as
	(
		select event_message_id
     , message_time
     , package_name	 
	 , message_source_name
	 , convert(time, left(right(message, 14), 13)) as elapsed_time
	 , execution_path
	 , len(execution_path) - len(replace(execution_path,'\','')) as depth
	 , nullif(left(execution_path, len(execution_path) - CHARINDEX('\', reverse(execution_path))), '') as parent
		from catalog.event_messages
		where 1 = 1
			and operation_id = 1
			and message like '%elapsed%'
	),
	run_time (node_id, message_time, package_name, execution_path, parent_id, elapsed_time )
	as
	(
		select msg.event_message_id as node_id, msg.message_time, msg.package_name, msg.execution_path, par.event_message_id as parent_id, msg.elapsed_time
		from raw_messages msg
			left join raw_messages par on msg.parent = par.execution_path
	)
select *
into #run_time
from run_time 
go


select message_time, package_name, execution_path, elapsed_time
--, CASE WHEN EXISTS (SELECT * FROM #run_time c2 WHERE c2.parent_id = c1.node_id) THEN 0 ELSE 1 END AS is_leaf
from #run_time c1
where CASE WHEN EXISTS (SELECT *
FROM #run_time c2
WHERE c2.parent_id = c1.node_id) THEN 0 ELSE 1 END  = 1
order by message_time desc, elapsed_time desc