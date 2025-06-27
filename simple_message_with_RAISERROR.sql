DECLARE @msg varchar(max) 
SET @msg = 'My Message'
SET @msg = FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss') + ': ' + @msg
RAISERROR (@msg, 0, 1) WITH NOWAIT