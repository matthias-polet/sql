use master -- Change to any database you want to deploy on.
GO

create or alter PROCEDURE dbo.usp_insert_table_sizes
AS
begin
    declare @datetime datetime
    DECLARE @currenttime varchar(30);

    if not exists (select *
    from sys.tables
    where name = 'table_sizes')
BEGIN
        SET @datetime = getdate();
        set @currenttime = FORMAT(@datetime,'o');;
        RAISERROR('%s - The table table_sizes does not exist, so we create it now.', 0, 1, @currenttime) WITH NOWAIT;
        SELECT
            @datetime as DateTime,
            db_name() as DatabaseName,
            t.name AS TableName,
            s.name AS SchemaName,
            p.rows,
            SUM(a.total_pages) * 8 AS TotalSpaceKB,
            SUM(a.used_pages) * 8 AS UsedSpaceKB,
            (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
        into dbo.table_sizes
        FROM
            sys.tables t
            INNER JOIN
            sys.indexes i ON t.object_id = i.object_id
            INNER JOIN
            sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
            INNER JOIN
            sys.allocation_units a ON p.partition_id = a.container_id
            LEFT OUTER JOIN
            sys.schemas s ON t.schema_id = s.schema_id
        where 1 = 2
        GROUP BY 
        t.name, s.name, p.rows

    end

    SET @datetime = getdate();
    set @currenttime = FORMAT(@datetime,'o');
    RAISERROR('%s - Insert Table Sizes', 0, 1, @currenttime) WITH NOWAIT;


    insert into dbo.table_sizes
    SELECT
        @datetime as DateTime,
        db_name() as DatabaseName,
        t.name AS TableName,
        s.name AS SchemaName,
        p.rows,
        SUM(a.total_pages) * 8 AS TotalSpaceKB,
        SUM(a.used_pages) * 8 AS UsedSpaceKB,
        (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
    FROM
        sys.tables t
        INNER JOIN
        sys.indexes i ON t.object_id = i.object_id
        INNER JOIN
        sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
        INNER JOIN
        sys.allocation_units a ON p.partition_id = a.container_id
        LEFT OUTER JOIN
        sys.schemas s ON t.schema_id = s.schema_id
    WHERE 
    t.name NOT LIKE 'dt%'
        AND t.is_ms_shipped = 0
        AND i.object_id > 255
    GROUP BY 
        t.name, s.name, p.rows
    ORDER BY 
        TotalSpaceKB DESC
    , t.name;

end
GO

create or alter PROCEDURE dbo.usp_get_table_sizes
AS
begin
    EXEC dbo.usp_insert_table_sizes;
    select *
    from dbo.table_sizes;
end
GO

-- Usage:
-- Run to get the table sizes
-- stores the result in dbo.table_sizes, so it can be used to track growth later
exec dbo.usp_get_table_sizes 

