-- Script per testare la stored procedure SP_InvioEmailPerDbLavoroPowershell
USE [I24DB]
GO

-- Test invio email con caratteri speciali in testo semplice
EXEC SP_InvioEmailPerDbLavoroPowershell
    @Mittente = 'antonio.sacco@i24.it',
    @StrTo = 'antonio.sacco@i24.it',
    @Subject = 'Test caratteri speciali: àèìòù €',
    @Body = 'Questo è un test di invio email con caratteri speciali:
    
• àèìòù (vocali accentate)
• €£$¥ (simboli valuta)
• ñçßÇÑ (altri caratteri speciali)
• αβγ (caratteri greci)
• 你好 (caratteri cinesi)

Questo test verifica che i caratteri speciali siano visualizzati correttamente nell''email.

Cordiali saluti,
Test System',
    @FormatoHTML = 0

-- Test invio email con caratteri speciali in formato HTML
EXEC SP_InvioEmailPerDbLavoroPowershell
    @Mittente = 'antonio.sacco@i24.it',
    @StrTo = 'antonio.sacco@i24.it',
    @Subject = 'Test HTML con caratteri speciali: àèìòù €',
    @Body = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Email</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .special { color: #0000FF; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Test di invio email HTML con caratteri speciali</h1>
    
    <p>Questo è un test per verificare che i <span class="special">caratteri speciali</span> siano visualizzati correttamente:</p>
    
    <ul>
        <li>àèìòù (vocali accentate)</li>
        <li>€£$¥ (simboli valuta)</li>
        <li>ñçßÇÑ (altri caratteri speciali)</li>
        <li>αβγ (caratteri greci)</li>
        <li>你好 (caratteri cinesi)</li>
    </ul>
    
    <table>
        <tr>
            <th>Carattere</th>
            <th>Descrizione</th>
        </tr>
        <tr>
            <td>è</td>
            <td>e con accento grave</td>
        </tr>
        <tr>
            <td>ç</td>
            <td>c con cediglia</td>
        </tr>
        <tr>
            <td>€</td>
            <td>simbolo euro</td>
        </tr>
    </table>
    
    <p>Cordiali saluti,<br>
    <strong>Test System</strong></p>
</body>
</html>',
    @FormatoHTML = 1

-- Test invio email con allegato
EXEC SP_InvioEmailPerDbLavoroPowershell
    @Mittente = 'antonio.sacco@i24.it',
    @StrTo = 'antonio.sacco@i24.it',
    @Subject = 'Test email con allegato',
    @Body = 'Questa email contiene un allegato di test.
    
Si prega di verificare che l''allegato sia ricevuto correttamente.

Cordiali saluti,
Test System',
    @Attachment = 'C:\Temp\test_attachment.txt',
    @FormatoHTML = 0

-- Attesa di 5 secondi tra i test
WAITFOR DELAY '00:00:05'
GO

-- Test con caratteri speciali in formato HTML - Versione più breve per test
EXEC SP_InvioEmailPerDbLavoroPowershell
    @Mittente = 'bg5team@bolognagomme.com',
    @StrTo = 'antoniosacco68@gmail.com',
    @Subject = 'Test HTML - Versione finale ✓',
    @Body = '<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; color: #333; }
        h1 { color: #0066cc; }
        .special { background-color: #ffffcc; padding: 10px; border: 1px solid #ccc; }
    </style>
</head>
<body>
    <h1>Test HTML - Versione Finale</h1>
    
    <p>Questo è un test della <strong>versione finale</strong> della procedura di invio email con caratteri speciali:</p>
    
    <div class="special">
        <ul>
            <li>Lettere accentate: àèìòù ÀÈÌÒÙ</li>
            <li>Simboli: € § ° ç @ # " '' & % / | \</li>
            <li>Emoji: 😀 👍 🚀 💻 🇮🇹</li>
        </ul>
    </div>
    
    <p>La procedura è ora completamente funzionante e pronta per l''uso in produzione.</p>
    
    <p><em>Cordiali saluti,<br>
    Test Automation Team</em></p>
</body>
</html>',
    @FormatoHTML = 1
GO

-- Attesa di 5 secondi tra i test
WAITFOR DELAY '00:00:05'
GO

-- Test con allegati multipli
-- Nota: assicurarsi che i file esistano nei percorsi specificati
EXEC SP_InvioEmailPerDbLavoroPowershell
    @Mittente = 'bg5team@bolognagomme.com',
    @StrTo = 'antoniosacco68@gmail.com',
    @Subject = 'Test con allegati multipli',
    @Body = '<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; color: #333; }
        h1 { color: #0066cc; }
    </style>
</head>
<body>
    <h1>Test con allegati multipli</h1>
    
    <p>Questa email contiene <strong>allegati multipli</strong> per testare la funzionalità di invio allegati.</p>
    
    <p>Gli allegati dovrebbero apparire correttamente e poter essere scaricati e aperti senza problemi.</p>
    
    <p><em>Cordiali saluti,<br>
    Test Automation Team</em></p>
</body>
</html>',
    @FormatoHTML = 1,
    @Attachment = 'C:\InvioEmailDb\Preventivo.pdf;C:\InvioEmailDb\Listino.pdf'
GO 