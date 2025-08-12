USE [I24DB]
GO

/****** Object: Table [dbo].[EmailStatistics] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmailStatistics]') AND type in (N'U'))
DROP TABLE [dbo].[EmailStatistics]
GO

CREATE TABLE [dbo].[EmailStatistics](
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [RunDate] [datetime] NOT NULL,
    [EmailsProcessed] [int] NOT NULL,
    [SuccessCount] [int] NOT NULL,
    [FailureCount] [int] NOT NULL,
    [TotalDurationMs] [int] NOT NULL,
    [BatchID] [uniqueidentifier] NULL,
    [Notes] [nvarchar](max) NULL,
 CONSTRAINT [PK_EmailStatistics] PRIMARY KEY CLUSTERED 
(
    [ID] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Indice per le statistiche per data ******/
CREATE NONCLUSTERED INDEX [IX_EmailStatistics_RunDate] ON [dbo].[EmailStatistics]
(
    [RunDate] DESC
)
GO

/****** Commento sulla tabella ******/
EXEC sys.sp_addextendedproperty @name=N'MS_Description', 
    @value=N'Tabella per le statistiche di invio email batch' , 
    @level0type=N'SCHEMA',
    @level0name=N'dbo', 
    @level1type=N'TABLE',
    @level1name=N'EmailStatistics'
GO 