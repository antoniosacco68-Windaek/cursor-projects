Sub EsportaXML()
    Dim ws As Worksheet
    Dim fso As Object
    Dim file As Object
    Dim filePath As String
    Dim xmlContent As String
    Dim i As Long, j As Long
    Dim lastRow As Long
    Dim lastCol As Long
    
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
    
    ' Costruisci il contenuto XML
    xmlContent = "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbCrLf
    xmlContent = xmlContent & "<PrezziManualiDistribuzioneIT>" & vbCrLf
    
    ' Cicla attraverso tutte le righe (saltando l'intestazione)
    For i = 2 To lastRow
        xmlContent = xmlContent & "  <Articolo>" & vbCrLf
        
        ' Cicla attraverso tutte le colonne
        For j = 1 To lastCol
            Dim headerName As String
            Dim cellValue As String
            
            ' Ottieni il nome della colonna dalla prima riga
            headerName = Trim(ws.Cells(1, j).Value)
            

            
            ' Pulisci il nome della colonna per XML
            headerName = Replace(headerName, " ", "_")
            headerName = Replace(headerName, ".", "_")
            headerName = Replace(headerName, "/", "_")
            headerName = Replace(headerName, "-", "_")
            headerName = Replace(headerName, "+", "_")
            headerName = Replace(headerName, "&", "_")
            headerName = Replace(headerName, "(", "_")
            headerName = Replace(headerName, ")", "_")
            headerName = Replace(headerName, "*", "_")
            
            ' Ottieni il valore della cella
            cellValue = CStr(ws.Cells(i, j).Value)
            
            ' Escape dei caratteri speciali XML
            cellValue = Replace(cellValue, "&", "&amp;")
            cellValue = Replace(cellValue, "<", "&lt;")
            cellValue = Replace(cellValue, ">", "&gt;")
            cellValue = Replace(cellValue, """", "&quot;")
            cellValue = Replace(cellValue, "'", "&apos;")
            
            ' Aggiungi l'elemento XML
            xmlContent = xmlContent & "    <" & headerName & ">" & cellValue & "</" & headerName & ">" & vbCrLf
        Next j
        
        xmlContent = xmlContent & "  </Articolo>" & vbCrLf
    Next i
    
    xmlContent = xmlContent & "</PrezziManualiDistribuzioneIT>"
    
    ' Salva il file XML
    Set file = fso.CreateTextFile(filePath, True)
    file.Write xmlContent
    file.Close
    
    ' Messaggio di conferma
    MsgBox "Esportazione completata!" & vbCrLf & "File salvato in: " & filePath, vbInformation
    
    ' Pulisci gli oggetti
    Set fso = Nothing
    Set file = Nothing
    Set ws = Nothing
End Sub

' Macro per eseguire l'esportazione rapidamente
Sub EsportaRapido()
    Call EsportaXML
End Sub 