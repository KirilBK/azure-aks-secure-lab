IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SubmittedItems')
BEGIN
    CREATE TABLE dbo.SubmittedItems
    (
        Id            INT IDENTITY(1,1) PRIMARY KEY,
        SubmittedName NVARCHAR(255) NOT NULL,
        Source        NVARCHAR(64)  NULL,        -- which component wrote the row
        SubmittedAt   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.SubmittedItems)
    INSERT INTO dbo.SubmittedItems (SubmittedName, Source) VALUES ('SEED', 'init-script');
GO
