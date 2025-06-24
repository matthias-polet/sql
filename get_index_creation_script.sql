CREATE or alter FUNCTION dbo.get_index_creation_script
(
    @table_name sysname,
    @index_name sysname
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    declare @sql nvarchar(max)


    select  @sql = 'CREATE' + case when ix.is_unique = 1 then ' UNIQUE ' else ' ' end + ix.type_desc + ' INDEX ' + ix.name + ' ON ' + t.name + ' ('
    FROM sys.indexes ix
    inner join sys.tables t on t.object_id = ix.object_id
    where ix.name = @index_name
      and t.name = @table_name



    select @sql = @sql + col.name + ', '
    FROM sys.indexes ix
    inner join sys.tables t on t.object_id = ix.object_id
    INNER JOIN sys.index_columns ic on ic.index_id = ix.index_id and ic.object_id = ix.object_id
    inner join sys.columns col on col.column_id = ic.column_id and col.object_id = ix.object_id
    where ix.name = @index_name
      and t.name = @table_name
    order by ic.key_ordinal -- (!)

    set @sql = left(@sql, len(@sql) - 1) + ')' 

    return @sql

END;
GO

-- Usage
select dbo.get_index_creation_script('MyTable', 'IXC_MyTable');
