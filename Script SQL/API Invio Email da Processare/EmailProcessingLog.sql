USE [I24DB]
GO

/****** Object: Table [dbo].[EmailProcessingLog] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EmailProcessingLog]') AND type in (N'U'))
DROP TABLE [dbo].[EmailProcessingLog]
GO

CREATE TABLE [dbo].[EmailProcessingLog](
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [EmailID] [uniqueidentifier] NOT NULL,
    [BatchID] [uniqueidentifier] NOT NULL,
    [ProcessingTime] [datetime] NOT NULL,
    [Mittente] [varchar](255) NULL,
    [Destinatario] [varchar](255) NULL,
    [Oggetto] [nvarchar](500) NULL,
    [Stato] [varchar](50) NOT NULL,
    [DettaglioStato] [nvarchar](max) NULL,
    [GmailMessageId] [varchar](255) NULL,
    [TempoElaborazioneMs] [int] NULL,
    [TentativiEffettuati] [int] NULL,
 CONSTRAINT [PK_EmailProcessingLog] PRIMARY KEY CLUSTERED 
(
    [ID] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Indici per velocizzare le ricerche ******/
CREATE NONCLUSTERED INDEX [IX_EmailProcessingLog_EmailID] ON [dbo].[EmailProcessingLog]
(
    [EmailID] ASC
)
GO

CREATE NONCLUSTERED INDEX [IX_EmailProcessingLog_BatchID] ON [dbo].[EmailProcessingLog]
(
    [BatchID] ASC
)
GO

CREATE NONCLUSTERED INDEX [IX_EmailProcessingLog_ProcessingTime] ON [dbo].[EmailProcessingLog]
(
    [ProcessingTime] DESC
)
GO

CREATE NONCLUSTERED INDEX [IX_EmailProcessingLog_Stato] ON [dbo].[EmailProcessingLog]
(
    [Stato] ASC
)
GO

/****** Commento sulla tabella ******/
EXEC sys.sp_addextendedproperty @name=N'MS_Description', 
    @value=N'Tabella per il log dettagliato di elaborazione delle email' , 
    @level0type=N'SCHEMA',
    @level0name=N'dbo', 
    @level1type=N'TABLE',
    @level1name=N'EmailProcessingLog'
GO 