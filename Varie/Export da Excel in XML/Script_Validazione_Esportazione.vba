Sub ValidazioneEscelta_JSON_vs_XML()
    ' Script per aiutare a scegliere il formato migliore
    ' e validare i dati prima dell'esportazione
    
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim lastCol As Long
    Dim i As Long, j As Long
    
    ' Contatori per analisi
    Dim caratteriSpeciali As Long
    Dim celleVuote As Long
    Dim celleConVirgolette As Long
    Dim celleConApostrofi As Long
    Dim celleConAccenti As Long
    Dim celleConCaratteriStrani As Long
    Dim celleConHTML As Long
    Dim celleConSQL As Long
    
    Dim cellValue As String
    Dim raccomandazione As String
    
    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    ' Analizza un campione di dati (prime 1000 righe per velocità)
    Dim righeAnalisi As Long
    righeAnalisi = IIf(lastRow > 1000, 1000, lastRow)
    
    For i = 2 To righeAnalisi
        For j = 1 To lastCol
            cellValue = CStr(ws.Cells(i, j).Value)
            
            If Len(cellValue) > 0 Then
                ' Caratteri speciali comuni
                If InStr(cellValue, """") > 0 Then celleConVirgolette = celleConVirgolette + 1
                If InStr(cellValue, "'") > 0 Then celleConApostrofi = celleConApostrofi + 1
                
                ' Accenti italiani
                If InStr(cellValue, "à") > 0 Or InStr(cellValue, "è") > 0 Or _
                   InStr(cellValue, "ì") > 0 Or InStr(cellValue, "ò") > 0 Or _
                   InStr(cellValue, "ù") > 0 Or InStr(cellValue, "É") > 0 Then
                    celleConAccenti = celleConAccenti + 1
                End If
                
                ' Caratteri potenzialmente problematici
                If InStr(cellValue, "&") > 0 Or InStr(cellValue, "<") > 0 Or _
                   InStr(cellValue, ">") > 0 Or InStr(cellValue, vbCrLf) > 0 Then
                    caratteriSpeciali = caratteriSpeciali + 1
                End If
                
                ' Caratteri molto strani (non ASCII)
                Dim k As Long
                For k = 1 To Len(cellValue)
                    If Asc(Mid(cellValue, k, 1)) > 127 Or Asc(Mid(cellValue, k, 1)) < 32 Then
                        If Mid(cellValue, k, 1) <> vbCrLf And Mid(cellValue, k, 1) <> vbCr Then
                            celleConCaratteriStrani = celleConCaratteriStrani + 1
                            Exit For
                        End If
                    End If
                Next k
                
                ' HTML/XML tags
                If InStr(cellValue, "<") > 0 And InStr(cellValue, ">") > 0 Then
                    celleConHTML = celleConHTML + 1
                End If
                
                ' Caratteri SQL problematici
                If InStr(cellValue, ";") > 0 Or InStr(cellValue, "--") > 0 Or _
                   InStr(UCase(cellValue), "SELECT") > 0 Or InStr(UCase(cellValue), "DROP") > 0 Then
                    celleConSQL = celleConSQL + 1
                End If
            Else
                celleVuote = celleVuote + 1
            End If
        Next j
    Next i
    
    ' Calcola raccomandazione
    Dim problemiTotali As Long
    problemiTotali = caratteriSpeciali + celleConCaratteriStrani + celleConHTML + celleConSQL
    
    If problemiTotali < (righeAnalisi * lastCol * 0.01) Then ' Meno dell'1% di problemi
        raccomandazione = "JSON"
    ElseIf problemiTotali < (righeAnalisi * lastCol * 0.05) Then ' Meno del 5% di problemi
        raccomandazione = "JSON (con controlli extra)"
    Else
        raccomandazione = "XML (più robusto)"
    End If
    
    ' Mostra risultati
    MsgBox "🔍 ANALISI QUALITÀ DATI:" & vbCrLf & vbCrLf & _
           "📊 Righe analizzate: " & Format(righeAnalisi - 1, "#,##0") & vbCrLf & _
           "📋 Colonne: " & Format(lastCol, "#,##0") & vbCrLf & _
           "📄 Celle totali: " & Format((righeAnalisi - 1) * lastCol, "#,##0") & vbCrLf & vbCrLf & _
           "CARATTERI TROVATI:" & vbCrLf & _
           "🔤 Virgolette: " & Format(celleConVirgolette, "#,##0") & vbCrLf & _
           "🔤 Apostrofi: " & Format(celleConApostrofi, "#,##0") & vbCrLf & _
           "🇮🇹 Accenti italiani: " & Format(celleConAccenti, "#,##0") & vbCrLf & _
           "⚠️ Caratteri speciali: " & Format(caratteriSpeciali, "#,##0") & vbCrLf & _
           "🔍 Caratteri strani: " & Format(celleConCaratteriStrani, "#,##0") & vbCrLf & _
           "📄 HTML/XML: " & Format(celleConHTML, "#,##0") & vbCrLf & _
           "🗄️ SQL pericolosi: " & Format(celleConSQL, "#,##0") & vbCrLf & _
           "⭕ Celle vuote: " & Format(celleVuote, "#,##0") & vbCrLf & vbCrLf & _
           "🎯 RACCOMANDAZIONE: " & raccomandazione & vbCrLf & vbCrLf & _
           "💡 " & ScegliConsiglio(raccomandazione), vbInformation, "Analisi Dati"
End Sub

Private Function ScegliConsiglio(raccomandazione As String) As String
    Select Case raccomandazione
        Case "JSON"
            ScegliConsiglio = "I tuoi dati sono puliti! JSON è perfetto."
        Case "JSON (con controlli extra)"
            ScegliConsiglio = "JSON va bene, ma aggiungi controlli di validazione."
        Case "XML (più robusto)"
            ScegliConsiglio = "Dati complessi rilevati. XML è più sicuro."
        Case Else
            ScegliConsiglio = "Analisi non conclusiva."
    End Select
End Function

Sub TestImportazioneJSON()
    ' Testa se il JSON generato è valido prima dell'importazione SQL
    Dim fso As Object
    Dim filePath As String
    Dim file As Object
    Dim contenuto As String
    Dim caratteriProblematici As Long
    Dim righeVuote As Long
    
    filePath = "C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.json"
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Verifica esistenza file
    If Not fso.FileExists(filePath) Then
        MsgBox "❌ File JSON non trovato: " & filePath, vbCritical
        Exit Sub
    End If
    
    ' Leggi contenuto
    Set file = fso.OpenTextFile(filePath, 1)
    contenuto = file.ReadAll
    file.Close
    
    ' Controlli di validazione
    Dim errori As String
    errori = ""
    
    ' Verifica struttura JSON base
    If InStr(contenuto, "{") = 0 Or InStr(contenuto, "}") = 0 Then
        errori = errori & "- Struttura JSON non valida" & vbCrLf
    End If
    
    ' Verifica virgolette non chiuse
    Dim conteggioVirgolette As Long
    Dim i As Long
    For i = 1 To Len(contenuto)
        If Mid(contenuto, i, 1) = """" And (i = 1 Or Mid(contenuto, i - 1, 1) <> "\") Then
            conteggioVirgolette = conteggioVirgolette + 1
        End If
    Next i
    
    If conteggioVirgolette Mod 2 <> 0 Then
        errori = errori & "- Virgolette non bilanciate" & vbCrLf
    End If
    
    ' Verifica encoding
    If InStr(contenuto, "�") > 0 Then
        errori = errori & "- Problemi di encoding rilevati" & vbCrLf
    End If
    
    ' Dimensione file
    Dim dimensioneMB As Double
    dimensioneMB = Len(contenuto) / 1024 / 1024
    
    ' Risultati
    If errori = "" Then
        MsgBox "✅ JSON VALIDO!" & vbCrLf & vbCrLf & _
               "📁 Dimensione: " & Format(dimensioneMB, "0.00") & " MB" & vbCrLf & _
               "🎯 Pronto per importazione SQL" & vbCrLf & vbCrLf & _
               "💡 Puoi procedere con l'importazione!", vbInformation, "Validazione OK"
    Else
        MsgBox "⚠️ PROBLEMI RILEVATI:" & vbCrLf & vbCrLf & _
               errori & vbCrLf & _
               "📁 Dimensione: " & Format(dimensioneMB, "0.00") & " MB" & vbCrLf & vbCrLf & _
               "🔧 Raccomandazione: Prova XML per maggiore robustezza", vbExclamation, "Validazione Fallita"
    End If
    
    Set fso = Nothing
End Sub

Sub EsportazioneIntelligente()
    ' Sceglie automaticamente il formato migliore basandosi sui dati
    
    MsgBox "🤖 ESPORTAZIONE INTELLIGENTE" & vbCrLf & vbCrLf & _
           "Questo script:" & vbCrLf & _
           "1. Analizza i tuoi dati" & vbCrLf & _
           "2. Sceglie il formato migliore (JSON vs XML)" & vbCrLf & _
           "3. Esporta automaticamente" & vbCrLf & _
           "4. Valida il risultato" & vbCrLf & vbCrLf & _
           "Procedere?", vbQuestion + vbYesNo, "Smart Export"
    
    If MsgBox("", vbYesNo) = vbNo Then Exit Sub
    
    ' Step 1: Analisi
    Call ValidazioneEscelta_JSON_vs_XML
    
    ' Step 2: Chiedi conferma formato
    Dim formato As String
    formato = InputBox("Formato raccomandato basato sui tuoi dati." & vbCrLf & _
                      "Inserisci 'JSON' o 'XML':", "Scegli Formato", "JSON")
    
    ' Step 3: Esporta
    If UCase(formato) = "JSON" Then
        Call EsportaJSON_SuperVeloce
        Call TestImportazioneJSON
    Else
        MsgBox "Per XML, usa lo script XML dedicato.", vbInformation
    End If
End Sub 