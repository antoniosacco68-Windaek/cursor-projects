Sub EsportaJSON_SuperVeloce()
    ' Versione JSON SUPER VELOCE - molto più compatta dell'XML
    ' JSON è tipicamente 3-5x più piccolo dell'XML equivalente
    ' FILTRO: Esporta solo righe con almeno un PM_ > 0
    
    Dim ws As Worksheet
    Dim fso As Object
    Dim file As Object
    Dim filePath As String
    Dim i As Long, j As Long
    Dim lastRow As Long
    Dim lastCol As Long
    Dim headerNames As Variant
    Dim cellValue As String
    Dim jsonLine As String
    Dim startTime As Double
    Dim righeFiltrate As Long
    Dim righeEsportate As Long
    
    ' Variabili per trovare le colonne PM_ dinamicamente
    Dim colPM_Std As Long, colPM_T24 As Long, colPM_B2b As Long, colPM_Collegati As Long
    
    ' Disabilita tutto per massima velocità
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Application.Calculation = xlCalculationManual
    Application.DisplayAlerts = False
    
    startTime = Timer
    
    ' Imposta il foglio di lavoro
    Set ws = ActiveSheet
    
    ' Crea la cartella se non esiste
    filePath = "C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\"
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(filePath) Then
        fso.CreateFolder filePath
    End If
    
    ' Percorso completo del file JSON
    filePath = filePath & "PrezziManualiDistribuzioneIT.json"
    
    ' Trova l'ultima riga e colonna con dati
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    ' Trova le colonne PM_ dinamicamente
    colPM_Std = 0: colPM_T24 = 0: colPM_B2b = 0: colPM_Collegati = 0
    For j = 1 To lastCol
        Select Case Trim(ws.Cells(1, j).Value)
            Case "PM_Std": colPM_Std = j
            Case "PM_T24": colPM_T24 = j
            Case "PM_B2b": colPM_B2b = j
            Case "PM_Collegati": colPM_Collegati = j
        End Select
    Next j
    
    ' Verifica che almeno una colonna PM_ sia stata trovata
    If colPM_Std = 0 And colPM_T24 = 0 And colPM_B2b = 0 And colPM_Collegati = 0 Then
        MsgBox "❌ ERRORE: Nessuna colonna PM_ trovata!" & vbCrLf & _
               "Assicurati che esistano colonne: PM_Std, PM_T24, PM_B2b, PM_Collegati", vbCritical
        Exit Sub
    End If
    
    ' Leggi tutte le intestazioni una volta sola
    ReDim headerNames(1 To lastCol)
    For j = 1 To lastCol
        headerNames(j) = PulisciNomeColonnaJSON(Trim(ws.Cells(1, j).Value))
    Next j
    
    ' Apri il file per scrittura
    Set file = fso.CreateTextFile(filePath, True)
    
    ' Scrivi header JSON
    file.WriteLine "{"
    file.WriteLine """PrezziManualiDistribuzioneIT"": ["
    
    ' Mostra progresso
    Debug.Print "Inizio esportazione JSON con FILTRO PM_ > 0..."
    Debug.Print "Righe totali da analizzare: " & (lastRow - 1)
    Debug.Print "Stima finale: Solo righe con almeno un PM_ > 0 (molto più piccolo!)"
    
    ' Inizializza contatori
    righeFiltrate = 0
    righeEsportate = 0
    
    ' Cicla attraverso tutte le righe (saltando l'intestazione)
    For i = 2 To lastRow
        ' Mostra progresso ogni 2500 righe (più frequente)
        If i Mod 2500 = 0 Then
            Debug.Print "Analizzate " & (i - 1) & " righe di " & (lastRow - 1) & " (" & Format((i - 1) / (lastRow - 1), "0%") & ") - Righe valide: " & righeEsportate
        End If
        
        ' FILTRO: Controlla se almeno un PM_ > 0
        Dim hasPrezzoValido As Boolean
        hasPrezzoValido = False
        
        If colPM_Std > 0 And IsNumeric(ws.Cells(i, colPM_Std).Value) Then
            If CDbl(ws.Cells(i, colPM_Std).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_T24 > 0 And IsNumeric(ws.Cells(i, colPM_T24).Value) Then
            If CDbl(ws.Cells(i, colPM_T24).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_B2b > 0 And IsNumeric(ws.Cells(i, colPM_B2b).Value) Then
            If CDbl(ws.Cells(i, colPM_B2b).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_Collegati > 0 And IsNumeric(ws.Cells(i, colPM_Collegati).Value) Then
            If CDbl(ws.Cells(i, colPM_Collegati).Value) > 0 Then hasPrezzoValido = True
        End If
        
        ' Salta questa riga se non ha prezzi validi
        If Not hasPrezzoValido Then
            righeFiltrate = righeFiltrate + 1
            GoTo NextRow
        End If
        
        ' Conta le righe effettivamente esportate
        righeEsportate = righeEsportate + 1
        
        ' Costruisci la riga JSON in una volta sola
        jsonLine = "  {"
        
        ' Cicla attraverso tutte le colonne
        For j = 1 To lastCol
            ' Ottieni il valore della cella
            cellValue = CStr(ws.Cells(i, j).Value)
            
            ' Escape JSON (molto più semplice dell'XML)
            cellValue = Replace(cellValue, "\", "\\")
            cellValue = Replace(cellValue, """", "\""")
            cellValue = Replace(cellValue, vbCrLf, "\n")
            cellValue = Replace(cellValue, vbCr, "\n")
            cellValue = Replace(cellValue, vbLf, "\n")
            
            ' Aggiungi alla riga JSON
            jsonLine = jsonLine & """" & headerNames(j) & """: """ & cellValue & """"
            If j < lastCol Then jsonLine = jsonLine & ", "
        Next j
        
        jsonLine = jsonLine & "}"
        
        ' Aggiungi virgola se non è l'ultima riga che sarà esportata
        ' (Non possiamo sapere a priori qual è l'ultima, quindi useremo un approccio diverso)
        file.WriteLine jsonLine & ","
        
NextRow:
    Next i
    
    ' Chiudi il file JSON (rimuovi l'ultima virgola)
    file.Close
    
    ' Riapri il file per correggere l'ultima virgola
    If righeEsportate > 0 Then
        Call CorreggiUltimaVirgola(filePath)
    End If
    
    ' Riapri e chiudi correttamente
    Set file = fso.OpenTextFile(filePath, 8) ' 8 = ForAppending
    file.WriteLine "]"
    file.WriteLine "}"
    file.Close
    
    ' Ripristina impostazioni
    Application.ScreenUpdating = True
    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    Application.DisplayAlerts = True
    
    ' Calcola tempo impiegato e dimensione file
    Dim totalTime As Double
    Dim fileSize As Long
    totalTime = Timer - startTime
    fileSize = FileLen(filePath)
    
    ' Messaggio di conferma con statistiche dettagliate
    MsgBox "🚀 ESPORTAZIONE JSON CON FILTRO COMPLETATA! 🚀" & vbCrLf & vbCrLf & _
           "⏱️ Tempo: " & Format(totalTime, "0.0") & " secondi" & vbCrLf & _
           "📊 Righe analizzate: " & Format(lastRow - 1, "#,##0") & vbCrLf & _
           "✅ Righe esportate: " & Format(righeEsportate, "#,##0") & " (con PM_ > 0)" & vbCrLf & _
           "🚫 Righe filtrate: " & Format(righeFiltrate, "#,##0") & " (senza prezzi)" & vbCrLf & _
           "📉 Riduzione: " & Format((righeFiltrate / (lastRow - 1)) * 100, "0.0") & "% di righe eliminate" & vbCrLf & _
           "🚀 Velocità: " & Format((lastRow - 1) / totalTime, "#,##0") & " righe/sec" & vbCrLf & _
           "📁 Dimensione: " & Format(fileSize / 1024 / 1024, "0.0") & " MB" & vbCrLf & _
           "🎯 File ultra-compatto con solo i dati utili!" & vbCrLf & vbCrLf & _
           "💾 File: " & filePath, vbInformation
    
    ' Pulisci gli oggetti
    Set fso = Nothing
    Set file = Nothing
    Set ws = Nothing
End Sub

' Funzione helper per pulire i nomi delle colonne per JSON
Private Function PulisciNomeColonnaJSON(nomeOriginale As String) As String
    Dim risultato As String
    risultato = nomeOriginale
    
    ' Per JSON usiamo camelCase invece di underscore
    risultato = Replace(risultato, " ", "")
    risultato = Replace(risultato, ".", "")
    risultato = Replace(risultato, "/", "")
    risultato = Replace(risultato, "-", "")
    risultato = Replace(risultato, "+", "Plus")
    risultato = Replace(risultato, "&", "And")
    risultato = Replace(risultato, "(", "")
    risultato = Replace(risultato, ")", "")
    risultato = Replace(risultato, "*", "")
    
    ' Assicurati che inizi con una lettera
    If Len(risultato) > 0 Then
        If IsNumeric(Left(risultato, 1)) Then
            risultato = "Field" & risultato
        End If
    End If
    
    PulisciNomeColonnaJSON = risultato
End Function

' Macro per fermare l'esportazione XML e passare a JSON
Sub FermaXMLPassaJSON()
    ' Ferma tutto
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    
    Dim risposta As VbMsgBoxResult
    risposta = MsgBox("Vuoi fermare l'esportazione XML e passare al JSON (molto più veloce)?", vbYesNo + vbQuestion, "Cambia formato")
    
    If risposta = vbYes Then
        Call EsportaJSON_SuperVeloce
    End If
End Sub

' Macro per esportazione JSON ultra rapida
Sub EsportaJSONRapido()
    Call EsportaJSON_SuperVeloce
End Sub

' Confronta dimensioni XML vs JSON
Sub StimaDimensioni()
    Dim righe As Long
    Dim colonne As Long
    Dim stimaXML As Long
    Dim stimaJSON As Long
    
    righe = ActiveSheet.Cells(ActiveSheet.Rows.Count, 1).End(xlUp).Row - 1
    colonne = ActiveSheet.Cells(1, ActiveSheet.Columns.Count).End(xlToLeft).Column
    
    ' Stima approssimativa (caratteri per riga)
    stimaXML = righe * colonne * 50  ' XML è molto verboso
    stimaJSON = righe * colonne * 20 ' JSON è molto più compatto
    
    MsgBox "📊 STIMA DIMENSIONI FILE:" & vbCrLf & vbCrLf & _
           "📄 Righe dati: " & Format(righe, "#,##0") & vbCrLf & _
           "📋 Colonne: " & Format(colonne, "#,##0") & vbCrLf & vbCrLf & _
           "🔸 XML stimato: ~" & Format(stimaXML / 1024 / 1024, "0") & " MB" & vbCrLf & _
           "🔹 JSON stimato: ~" & Format(stimaJSON / 1024 / 1024, "0") & " MB" & vbCrLf & vbCrLf & _
           "💡 JSON è ~" & Format((1 - (stimaJSON / stimaXML)) * 100, "0") & "% più piccolo!" & vbCrLf & _
           "⚡ E molto più veloce da generare!", vbInformation, "Confronto Formati"
End Sub

' Funzione helper per correggere l'ultima virgola nel JSON
Private Sub CorreggiUltimaVirgola(filePath As String)
    Dim fso As Object
    Dim file As Object
    Dim contenuto As String
    Dim pos As Long
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Leggi tutto il contenuto del file
    Set file = fso.OpenTextFile(filePath, 1) ' 1 = ForReading
    contenuto = file.ReadAll
    file.Close
    
    ' Trova l'ultima virgola e rimuovila
    pos = InStrRev(contenuto, ",")
    If pos > 0 Then
        contenuto = Left(contenuto, pos - 1) & Mid(contenuto, pos + 1)
    End If
    
    ' Riscrivi il file senza l'ultima virgola
    Set file = fso.CreateTextFile(filePath, True)
    file.Write contenuto
    file.Close
    
    Set fso = Nothing
End Sub

' Macro per testare quante righe verrebbero esportate con il filtro PM_ > 0
Sub TestFiltroPM()
    Dim ws As Worksheet
    Dim i As Long, j As Long
    Dim lastRow As Long
    Dim lastCol As Long
    Dim colPM_Std As Long, colPM_T24 As Long, colPM_B2b As Long, colPM_Collegati As Long
    Dim righeTotali As Long
    Dim righeConPrezzi As Long
    Dim righeSenzaPrezzi As Long
    Dim hasPrezzoValido As Boolean
    
    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    ' Trova le colonne PM_ dinamicamente
    colPM_Std = 0: colPM_T24 = 0: colPM_B2b = 0: colPM_Collegati = 0
    For j = 1 To lastCol
        Select Case Trim(ws.Cells(1, j).Value)
            Case "PM_Std": colPM_Std = j
            Case "PM_T24": colPM_T24 = j
            Case "PM_B2b": colPM_B2b = j
            Case "PM_Collegati": colPM_Collegati = j
        End Select
    Next j
    
    ' Verifica colonne
    If colPM_Std = 0 And colPM_T24 = 0 And colPM_B2b = 0 And colPM_Collegati = 0 Then
        MsgBox "❌ ERRORE: Nessuna colonna PM_ trovata!", vbCritical
        Exit Sub
    End If
    
    ' Analizza tutte le righe
    righeTotali = lastRow - 1
    righeConPrezzi = 0
    righeSenzaPrezzi = 0
    
    For i = 2 To lastRow
        hasPrezzoValido = False
        
        ' Controlla ogni colonna PM_
        If colPM_Std > 0 And IsNumeric(ws.Cells(i, colPM_Std).Value) Then
            If CDbl(ws.Cells(i, colPM_Std).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_T24 > 0 And IsNumeric(ws.Cells(i, colPM_T24).Value) Then
            If CDbl(ws.Cells(i, colPM_T24).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_B2b > 0 And IsNumeric(ws.Cells(i, colPM_B2b).Value) Then
            If CDbl(ws.Cells(i, colPM_B2b).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If colPM_Collegati > 0 And IsNumeric(ws.Cells(i, colPM_Collegati).Value) Then
            If CDbl(ws.Cells(i, colPM_Collegati).Value) > 0 Then hasPrezzoValido = True
        End If
        
        If hasPrezzoValido Then
            righeConPrezzi = righeConPrezzi + 1
        Else
            righeSenzaPrezzi = righeSenzaPrezzi + 1
        End If
    Next i
    
    ' Mostra risultati
    MsgBox "🔍 ANALISI FILTRO PM_ > 0:" & vbCrLf & vbCrLf & _
           "📊 Righe totali: " & Format(righeTotali, "#,##0") & vbCrLf & _
           "✅ Righe con prezzi (da esportare): " & Format(righeConPrezzi, "#,##0") & vbCrLf & _
           "🚫 Righe senza prezzi (da saltare): " & Format(righeSenzaPrezzi, "#,##0") & vbCrLf & vbCrLf & _
           "📉 Riduzione file: " & Format((righeSenzaPrezzi / righeTotali) * 100, "0.0") & "%" & vbCrLf & _
           "⚡ Velocità attesa: SUPER VELOCE!" & vbCrLf & vbCrLf & _
           "💡 Solo " & Format(righeConPrezzi, "#,##0") & " righe verranno esportate!" & vbCrLf & _
           "🎯 File finale molto più piccolo e veloce!", vbInformation, "Test Filtro"
End Sub 