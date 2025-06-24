CREATE OR ALTER FUNCTION dbo.get_index_creation_script
(
    @table_name SYSNAME,
    @index_name SYSNAME
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    -- Select the SQL command for creating the specified index on the specified table.
    SELECT @sql = 'CREATE' + CASE WHEN ix.is_unique = 1 THEN ' UNIQUE ' ELSE '' END + ix.type_desc + ' INDEX ' + ix.name + ' ON ' + t.name + ' ('
    FROM sys.indexes ix
        INNER JOIN sys.tables t ON t.object_id = ix.object_id
    WHERE ix.name = @index_name
        AND t.name = @table_name

    -- Add columns to the SQL command according to their order in the index.
    SELECT @sql = @sql + col.name + ', '
    FROM sys.indexes ix
        INNER JOIN sys.tables t ON t.object_id = ix.object_id
        INNER JOIN sys.index_columns ic ON ic.index_id = ix.index_id AND ic.object_id = ix.object_id
        INNER JOIN sys.columns col ON col.column_id = ic.column_id AND col.object_id = ix.object_id
    WHERE ix.name = @index_name
        AND t.name = @table_name
    ORDER BY ic.key_ordinal -- (!) Sort the columns according to their order in the index.

    -- Remove the final comma from the SQL command and replace it by a closing bracket.
    SET @sql = LEFT(@sql, LEN(@sql) - 1) + ')'

    RETURN @sql
END;
GO

-- Usage
SELECT dbo.get_index_creation_script('MyTable', 'IXC_MyTable');