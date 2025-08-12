USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[ImportaPreventivoWebJson]    Script Date: 13/05/2025 10:50:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ImportaPreventivoWebJson]
    @JsonFilePath NVARCHAR(MAX)
AS
BEGIN
    -- Dichiarazioni
    DECLARE @json NVARCHAR(MAX);
    DECLARE @sql nvarchar(4000);
    -- Tronca la tabella staging
    TRUNCATE TABLE [dbo].[PreventivoWebJson_Staging];

    -- Leggi il contenuto del file JSON
    SET @sql = 'SELECT @json = BulkColumn FROM OPENROWSET (BULK ''' + @JsonFilePath + ''', SINGLE_CLOB) AS x';
    EXEC sp_executesql @sql, N'@json NVARCHAR(MAX) OUTPUT', @json = @json OUTPUT;

    -- Inserisci i dati nella tabella di staging
    INSERT INTO [dbo].[PreventivoWebJson_Staging]
    SELECT
        NULLIF(JSON_VALUE(@json, '$.DataRichiesta'), ''),
        NULLIF(JSON_VALUE(@json, '$.Nome'), ''),
        NULLIF(JSON_VALUE(@json, '$.Cognome'), ''),
        NULLIF(JSON_VALUE(@json, '$.Email'), ''),
        NULLIF(JSON_VALUE(@json, '$.Telefono'), ''),
        NULLIF(JSON_VALUE(@json, '$.CAP'), ''),
        NULLIF(JSON_VALUE(@json, '$.Negozio'), ''),
        NULLIF(JSON_VALUE(@json, '$.TargaVeicolo'), ''),
        NULLIF(JSON_VALUE(@json, '$.Marca'), ''),
        NULLIF(JSON_VALUE(@json, '$.Modello'), ''),
        NULLIF(JSON_VALUE(@json, '$.TipoPreventivo'), ''),
        NULLIF(JSON_VALUE(@json, '$.Larghezza'), ''),
        NULLIF(JSON_VALUE(@json, '$.Spalla'), ''),
        NULLIF(JSON_VALUE(@json, '$.Diametro'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodCar'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodVel'), ''),
        NULLIF(JSON_VALUE(@json, '$.Stagionalita'), ''),
		NULLIF(JSON_VALUE(@json, '$.NumeroPneumatici'), ''),
        NULLIF(JSON_VALUE(@json, '$.FasciaDiPrezzo'), ''),
        NULLIF(JSON_VALUE(@json, '$.Km'), ''),
        NULLIF(JSON_VALUE(@json, '$.TipoManutenzione'), ''),
        NULLIF(JSON_VALUE(@json, '$.LarghezzaMotoAnt'), ''),
        NULLIF(JSON_VALUE(@json, '$.SpallaMotoAnt'), ''),
        NULLIF(JSON_VALUE(@json, '$.DiametroMotoAnt'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodCarMotoAnt'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodVelMotoAnt'), ''),
        NULLIF(JSON_VALUE(@json, '$.LarghezzaMotoPost'), ''),
        NULLIF(JSON_VALUE(@json, '$.SpallaMotoPost'), ''),
        NULLIF(JSON_VALUE(@json, '$.DiametroMotoPost'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodCarMotoPost'), ''),
        NULLIF(JSON_VALUE(@json, '$.CodVelMotoPost'), ''),
        NULLIF(JSON_VALUE(@json, '$.CorpoMessaggio'), '')

    -- Sposta i dati dalla tabella staging alla tabella finale

    INSERT INTO [dbo].[PreventivoWebJson]
    SELECT *
    FROM [dbo].[PreventivoWebJson_Staging];

END;
