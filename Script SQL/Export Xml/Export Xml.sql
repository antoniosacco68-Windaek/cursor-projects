USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[Ant_ExportXml_PowerShell]    Script Date: 11/04/2025 10:45:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Ant_ExportXml_PowerShell]
(
    @db_name    VARCHAR(100), -- Nome DB "I24BO"
    @table_name VARCHAR(100), -- Nome TBL o VIEW "Ant_OffSpec_euroimport"
    @file_name  VARCHAR(200)  -- Nome e Percorso File di Output "C:\temp\Test.xml"
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Assicuriamoci che il percorso del file sia assoluto
    IF LEFT(@file_name, 1) <> 'C' AND LEFT(@file_name, 1) <> 'D' AND LEFT(@file_name, 1) <> '\\'
    BEGIN
        SET @file_name = 'C:\temp\' + @file_name;
        PRINT 'Percorso file convertito in percorso assoluto: ' + @file_name;
    END

    DECLARE @sql NVARCHAR(MAX),
            @root_element_name NVARCHAR(128);
    
    -- Il nome dell'elemento radice è il nome della tabella con una 's' alla fine
    SET @root_element_name = @table_name + 's';
    
    -- Costruiamo una lista di colonne rinominate sostituendo spazi e caratteri non validi con underscore
    DECLARE @column_list NVARCHAR(MAX);
    SET @column_list = N'';
    
    -- Query per generare la lista di colonne con nomi XML validi
    DECLARE @col_query NVARCHAR(MAX);
    SET @col_query = N'
    USE ' + QUOTENAME(@db_name) + N';
    
    SELECT @column_list_out = STRING_AGG(
        QUOTENAME(c.name) + '' AS '' + QUOTENAME(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(
                                                        REPLACE(
                                                            REPLACE(
                                                                REPLACE(
                                                                    REPLACE(c.name, '' '', ''_''),  -- Sostituisci spazi con underscore
                                                                    ''['', ''''),                   -- Rimuovi parentesi quadre
                                                                '']'', ''''),                       -- Rimuovi parentesi quadre
                                                            '','', ''''),                           -- Rimuovi virgole
                                                        ''('', ''''),                               -- Rimuovi parentesi tonde
                                                    '')'', ''''),                                   -- Rimuovi parentesi tonde
                                                ''à'', ''a''),                                      -- Sostituisci lettere accentate
                                            ''è'', ''e''),
                                        ''é'', ''e''),
                                    ''ì'', ''i''),
                                ''ò'', ''o''),
                            ''ù'', ''u''),
                        ''À'', ''A''),
                    ''È'', ''E''),
                ''É'', ''E'')
            ), 
            '', ''
        )
    FROM sys.columns c
    JOIN sys.objects o ON c.object_id = o.object_id
    JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE o.name = @table_name_in
      AND s.name = ''dbo''
      AND o.type IN (''U'', ''V'');
    ';
    
    -- Esegui la query per ottenere la lista di colonne rinominate
    EXEC sp_executesql @col_query, 
                      N'@table_name_in NVARCHAR(128), @column_list_out NVARCHAR(MAX) OUTPUT', 
                      @table_name_in = @table_name, 
                      @column_list_out = @column_list OUTPUT;
    
    -- Se non è stata trovata nessuna colonna, genera un errore
    IF @column_list IS NULL OR LEN(@column_list) = 0
    BEGIN
        RAISERROR('Nessuna colonna trovata per la tabella %s nello schema dbo.', 16, 1, @table_name);
        RETURN;
    END
    
    -- Creazione tabella temporanea per memorizzare il risultato XML
    IF OBJECT_ID('tempdb..#XmlOutput') IS NOT NULL
        DROP TABLE #XmlOutput;
    
    CREATE TABLE #XmlOutput (XmlContent XML);
    
    -- Costruiamo la query dinamica per generare l'XML direttamente da SQL Server
    SET @sql = N'
    USE ' + QUOTENAME(@db_name) + N';
    
    INSERT INTO #XmlOutput (XmlContent)
    SELECT (
        SELECT ' + @column_list + N'
        FROM [dbo].' + QUOTENAME(@table_name) + N'
        FOR XML PATH(''' + @table_name + N'''), ROOT(''' + @root_element_name + N''')
    );';
    
    -- Esegui la query dinamica per popolare la tabella temporanea
    BEGIN TRY
        EXEC sp_executesql @sql;
        
        -- Recupera il contenuto XML dalla tabella temporanea
        DECLARE @xml_content XML;
        SELECT @xml_content = XmlContent FROM #XmlOutput;
        
        -- Converti l'XML in stringa
        DECLARE @xml_string NVARCHAR(MAX);
        SET @xml_string = CAST(@xml_content AS NVARCHAR(MAX));
        
        -- Dichiarazione di @cmd come VARCHAR(8000)
        DECLARE @cmd VARCHAR(8000);
        DECLARE @result TABLE (output VARCHAR(4000));
        
        -- Elimina eventuali file esistenti
        SET @cmd = 'if exist "' + @file_name + '" del "' + @file_name + '"';
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        -- Test di scrittura
        SET @cmd = 'echo Test > "' + @file_name + '"';
        DELETE FROM @result;
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        IF EXISTS (SELECT 1 FROM @result WHERE output IS NOT NULL AND output LIKE '%trovare%')
        BEGIN
            -- La directory potrebbe non esistere, prova a crearla
            DECLARE @directory VARCHAR(500) = LEFT(@file_name, CHARINDEX('\', REVERSE(@file_name)) - 1);
            SET @cmd = 'mkdir "' + @directory + '" 2>nul';
            DELETE FROM @result;
            INSERT INTO @result
            EXEC xp_cmdshell @cmd;
            
            -- Riprova dopo aver creato la directory
            SET @cmd = 'echo Test > "' + @file_name + '"';
            DELETE FROM @result;
            INSERT INTO @result
            EXEC xp_cmdshell @cmd;
            
            IF EXISTS (SELECT 1 FROM @result WHERE output IS NOT NULL AND output LIKE '%trovare%')
            BEGIN
                RAISERROR('Impossibile scrivere nel file: %s. Verifica che la directory esista e che SQL Server abbia i permessi di scrittura.', 16, 1, @file_name);
                RETURN;
            END
        END
        
        -- Elimina il file di test
        SET @cmd = 'del "' + @file_name + '"';
        DELETE FROM @result;
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        -- Metodo diretto per file di piccole dimensioni
        IF LEN(@xml_string) < 7500
        BEGIN
            -- Converti caratteri speciali
            DECLARE @xml_escaped VARCHAR(8000);
            SET @xml_escaped = REPLACE(REPLACE(@xml_string, '"', '""'), '<', '^<');
            SET @xml_escaped = REPLACE(REPLACE(@xml_escaped, '>', '^>'), '&', '^&');
            SET @xml_escaped = REPLACE(REPLACE(@xml_escaped, '|', '^|'), '%', '%%');
            SET @xml_escaped = REPLACE(REPLACE(@xml_escaped, '^', '^^'), '(', '^(');
            SET @xml_escaped = REPLACE(@xml_escaped, ')', '^)');
            
            -- Scrivi il file in un colpo solo
            SET @cmd = 'echo ' + @xml_escaped + ' > "' + @file_name + '"';
            DELETE FROM @result;
            INSERT INTO @result
            EXEC xp_cmdshell @cmd;
            
            -- Verifica se il file è stato creato
            SET @cmd = 'if exist "' + @file_name + '" echo "File creato con successo"';
            DELETE FROM @result;
            INSERT INTO @result
            EXEC xp_cmdshell @cmd;
            
            IF EXISTS (SELECT 1 FROM @result WHERE output LIKE '%File creato con successo%')
            BEGIN
                PRINT 'File XML generato con successo: ' + @file_name;
                RETURN;
            END
        END
        
        -- Metodo alternativo: scrittura diretta tramite OPENROWSET
        DECLARE @sql_for_file NVARCHAR(MAX);
        SET @sql_for_file = N'
        DECLARE @xml_string VARCHAR(MAX) = ''' + REPLACE(@xml_string, '''', '''''') + ''';
        
        -- Crea una tabella temporanea con il contenuto XML
        IF OBJECT_ID(''tempdb..##TempXml'') IS NOT NULL
            DROP TABLE ##TempXml;
            
        CREATE TABLE ##TempXml (XmlContent VARCHAR(MAX));
        
        -- Inserisci il contenuto XML nella tabella temporanea
        INSERT INTO ##TempXml (XmlContent) VALUES (@xml_string);';
        
        -- Esegui la prima parte della query
        EXEC sp_executesql @sql_for_file;
        
        -- Ora usa BULK INSERT per scrivere il file
        SET @cmd = 'bcp "SELECT XmlContent FROM ##TempXml" queryout "' + @file_name + '" -c -T -S ' + @@SERVERNAME;
        DELETE FROM @result;
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        -- Verifica se il BCP ha avuto successo
        IF EXISTS (SELECT 1 FROM @result WHERE output LIKE '%righe copiate%')
        BEGIN
            PRINT 'File XML generato con successo tramite BCP: ' + @file_name;
            
            -- Elimina la tabella temporanea
            IF OBJECT_ID('tempdb..##TempXml') IS NOT NULL
                DROP TABLE ##TempXml;
                
            RETURN;
        END
        
        -- Scelta alternativa: scrittura tramite comandi CMD separati per ogni riga XML
        PRINT 'Tentativo di scrittura file tramite metodo cmd...';
        
        -- Crea file con intestazione XML
        SET @cmd = 'echo ^<?xml version="1.0" encoding="UTF-8"?^> > "' + @file_name + '"';
        DELETE FROM @result;
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        -- Scrivi il contenuto in blocchi molto piccoli per evitare problemi
        DECLARE @pos INT = 1;
        DECLARE @chunk VARCHAR(1000);
        DECLARE @len INT = LEN(@xml_string);
        
        WHILE @pos <= @len
        BEGIN
            SET @chunk = SUBSTRING(@xml_string, @pos, 1000);
            
            -- Escape caratteri speciali
            SET @chunk = REPLACE(REPLACE(@chunk, '"', '""'), '<', '^<');
            SET @chunk = REPLACE(REPLACE(@chunk, '>', '^>'), '&', '^&');
            SET @chunk = REPLACE(REPLACE(@chunk, '|', '^|'), '%', '%%');
            SET @chunk = REPLACE(REPLACE(@chunk, '^', '^^'), '(', '^(');
            SET @chunk = REPLACE(@chunk, ')', '^)');
            
            -- Scrivi nel file
            SET @cmd = 'echo ' + @chunk + ' >> "' + @file_name + '"';
            EXEC xp_cmdshell @cmd, no_output;
            
            SET @pos = @pos + 1000;
        END
        
        -- Verifica se il file è stato creato
        SET @cmd = 'if exist "' + @file_name + '" echo "File creato con successo"';
        DELETE FROM @result;
        INSERT INTO @result
        EXEC xp_cmdshell @cmd;
        
        IF EXISTS (SELECT 1 FROM @result WHERE output LIKE '%File creato con successo%')
        BEGIN
            PRINT 'File XML generato con successo con metodo cmd: ' + @file_name;
        END
        ELSE
        BEGIN
            RAISERROR('Impossibile creare il file XML: %s', 16, 1, @file_name);
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Errore durante la generazione del file XML: %s', 16, 1, @ErrorMessage);
        RETURN;
    END CATCH
    
    SET NOCOUNT OFF;
END
GO