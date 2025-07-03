CREATE DATABASE test_backup;
go
declare @test_backup_bak sysname = '/var/opt/mssql/backup/test_backup.bak';
BACKUP DATABASE test_backup TO DISK = @test_backup_bak;
go

declare @test_backup_bak sysname = '/var/opt/mssql/backup/test_backup.bak';
RESTORE DATABASE test_backup FROM DISK=@test_backup_bak WITH REPLACE;
GO

declare @test_backup_bak sysname = '/var/opt/mssql/backup/test_backup.bak';
ALTER DATABASE test_backup SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE test_backup SET READ_WRITE WITH NO_WAIT;
RESTORE DATABASE test_backup FROM DISK=@test_backup_bak WITH REPLACE;
ALTER DATABASE test_backup SET READ_ONLY WITH NO_WAIT;
ALTER DATABASE test_backup SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

