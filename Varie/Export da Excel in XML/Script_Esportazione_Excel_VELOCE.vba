Sub EsportaXML_Veloce()
    ' Versione ottimizzata per grandi volumi di dati
    ' Scrive direttamente su file invece di costruire tutto in memoria
    
    Dim ws As Worksheet
    Dim fso As Object
    Dim file As Object
    Dim filePath As String
    Dim i As Long, j As Long
    Dim lastRow As Long
    Dim lastCol As Long
    Dim headerNames As Variant
    Dim cellValue As String
    Dim startTime As Double
    Dim progressForm As Object
    
    ' Disabilita aggiornamento schermo per velocità
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Application.Calculation = xlCalculationManual
    
    startTime = Timer
    
    ' Imposta il foglio di lavoro
    Set ws = ActiveSheet
    
    ' Crea la cartella se non esiste
    filePath = "C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\"
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(filePath) Then
        fso.CreateFolder filePath
    End If
    
    ' Percorso completo del file XML
    filePath = filePath & "PrezziManualiDistribuzioneIT.xml"
    
    ' Trova l'ultima riga e colonna con dati
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    ' Leggi tutte le intestazioni una volta sola
    ReDim headerNames(1 To lastCol)
    For j = 1 To lastCol
        headerNames(j) = PulisciNomeColonna(Trim(ws.Cells(1, j).Value))
    Next j
    
    ' Apri il file per scrittura
    Set file = fso.CreateTextFile(filePath, True)
    
    ' Scrivi header XML
    file.WriteLine "<?xml version=""1.0"" encoding=""UTF-8""?>"
    file.WriteLine "<PrezziManualiDistribuzioneIT>"
    
    ' Mostra progresso
    Debug.Print "Inizio esportazione di " & (lastRow - 1) & " righe..."
    
    ' Cicla attraverso tutte le righe (saltando l'intestazione)
    For i = 2 To lastRow
        ' Mostra progresso ogni 5000 righe
        If i Mod 5000 = 0 Then
            Debug.Print "Processate " & (i - 1) & " righe di " & (lastRow - 1) & " (" & Format((i - 1) / (lastRow - 1), "0%") & ")"
        End If
        
        file.WriteLine "  <Articolo>"
        
        ' Cicla attraverso tutte le colonne
        For j = 1 To lastCol
            ' Ottieni il valore della cella
            cellValue = CStr(ws.Cells(i, j).Value)
            
            ' Escape caratteri speciali XML (solo se necessario)
            If InStr(cellValue, "&") > 0 Then cellValue = Replace(cellValue, "&", "&amp;")
            If InStr(cellValue, "<") > 0 Then cellValue = Replace(cellValue, "<", "&lt;")
            If InStr(cellValue, ">") > 0 Then cellValue = Replace(cellValue, ">", "&gt;")
            If InStr(cellValue, """") > 0 Then cellValue = Replace(cellValue, """", "&quot;")
            If InStr(cellValue, "'") > 0 Then cellValue = Replace(cellValue, "'", "&apos;")
            
            ' Scrivi direttamente l'elemento XML
            file.WriteLine "    <" & headerNames(j) & ">" & cellValue & "</" & headerNames(j) & ">"
        Next j
        
        file.WriteLine "  </Articolo>"
    Next i
    
    ' Chiudi il file XML
    file.WriteLine "</PrezziManualiDistribuzioneIT>"
    file.Close
    
    ' Ripristina impostazioni
    Application.ScreenUpdating = True
    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    
    ' Calcola tempo impiegato
    Dim totalTime As Double
    totalTime = Timer - startTime
    
    ' Messaggio di conferma con statistiche
    MsgBox "Esportazione completata in " & Format(totalTime, "0.0") & " secondi!" & vbCrLf & _
           "Righe esportate: " & Format(lastRow - 1, "#,##0") & vbCrLf & _
           "Velocità: " & Format((lastRow - 1) / totalTime, "#,##0") & " righe/sec" & vbCrLf & vbCrLf & _
           "File salvato in: " & filePath, vbInformation
    
    ' Pulisci gli oggetti
    Set fso = Nothing
    Set file = Nothing
    Set ws = Nothing
End Sub

' Funzione helper per pulire i nomi delle colonne
Private Function PulisciNomeColonna(nomeOriginale As String) As String
    Dim risultato As String
    risultato = nomeOriginale
    
    ' Pulisci il nome della colonna per XML
    risultato = Replace(risultato, " ", "_")
    risultato = Replace(risultato, ".", "_")
    risultato = Replace(risultato, "/", "_")
    risultato = Replace(risultato, "-", "_")
    risultato = Replace(risultato, "+", "_")
    risultato = Replace(risultato, "&", "_")
    risultato = Replace(risultato, "(", "_")
    risultato = Replace(risultato, ")", "_")
    risultato = Replace(risultato, "*", "_")
    
    PulisciNomeColonna = risultato
End Function

' Macro per eseguire l'esportazione veloce
Sub EsportaRapidoVeloce()
    Call EsportaXML_Veloce
End Sub

' Macro per confrontare le performance
Sub TestPerformance()
    Dim startTime As Double
    Dim endTime As Double
    Dim righe As Long
    
    righe = ActiveSheet.Cells(ActiveSheet.Rows.Count, 1).End(xlUp).Row - 1
    
    MsgBox "Iniziando test di performance su " & Format(righe, "#,##0") & " righe..." & vbCrLf & _
           "Usa la versione VELOCE per grandi volumi di dati!", vbInformation
    
    startTime = Timer
    Call EsportaXML_Veloce
    endTime = Timer
    
    MsgBox "Performance test completato!" & vbCrLf & _
           "Tempo impiegato: " & Format(endTime - startTime, "0.0") & " secondi" & vbCrLf & _
           "Velocità: " & Format(righe / (endTime - startTime), "#,##0") & " righe/sec", vbInformation
End Sub 