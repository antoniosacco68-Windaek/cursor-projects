Sub EsportazioneCSV_StrutturaFissa()
    Dim ws As Worksheet
    Dim ultimaRiga As Long
    Dim i As Long
    Dim percorsoFile As String
    Dim nomeFile As String
    Dim fileNum As Integer
    Dim tempoInizio As Double
    Dim tempoFine As Double
    Dim righeProcesate As Long
    
    ' Configurazione
    Set ws = ActiveSheet
    percorsoFile = "C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\"
    nomeFile = "PrezziManualiDistribuzioneIT.csv"
    
    ' Trova le colonne dinamicamente
    Dim colonne As Object
    Set colonne = TrovaColonne(ws)
    
    ' Verifica che tutte le colonne necessarie siano presenti
    If Not VerificaColonnePresenti(colonne) Then
        MsgBox "ERRORE: Non tutte le colonne necessarie sono presenti nel foglio!", vbCritical
        Exit Sub
    End If
    
    ' Crea la directory se non esiste
    If Dir(percorsoFile, vbDirectory) = "" Then
        MkDir percorsoFile
    End If
    
    ' Trova ultima riga con dati
    ultimaRiga = ws.Cells(ws.Rows.Count, colonne("Art_Id")).End(xlUp).Row
    
    ' Messaggio di avvio
    tempoInizio = Timer
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    
    MsgBox "Inizio esportazione CSV con struttura fissa..." & vbCrLf & _
           "Righe da processare: " & (ultimaRiga - 1) & vbCrLf & _
           "File di destinazione: " & percorsoFile & nomeFile, vbInformation
    
    ' Apri file per scrittura
    fileNum = FreeFile
    Open percorsoFile & nomeFile For Output As #fileNum
    
    ' Scrivi header fisso (sempre lo stesso ordine)
    Print #fileNum, "Art_Id,ART_CODICE,classificatore3,Descrizione,MARCA,ART_STAGIONE," & _
                   "PM_Std,PM_Std_Data,PM_T24,PM_T24_Data,PM_B2b,PM_B2b_Data," & _
                   "PM_Collegati,PM_Collegati_Data"
    
    ' Processa i dati riga per riga
    For i = 2 To ultimaRiga
        ' Scrivi la riga nel formato fisso
        Print #fileNum, EstraiRigaCSV(ws, i, colonne)
        
        ' Mostra progresso ogni 10000 righe
        righeProcesate = righeProcesate + 1
        If righeProcesate Mod 10000 = 0 Then
            DoEvents
            Application.StatusBar = "Processate " & righeProcesate & " righe di " & (ultimaRiga - 1)
        End If
    Next i
    
    ' Chiudi file
    Close #fileNum
    
    ' Ripristina impostazioni
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.StatusBar = False
    
    ' Calcola tempo impiegato
    tempoFine = Timer
    
    ' Messaggio finale
    MsgBox "✅ ESPORTAZIONE CSV COMPLETATA!" & vbCrLf & vbCrLf & _
           "📁 File salvato in: " & percorsoFile & nomeFile & vbCrLf & _
           "📊 Righe processate: " & righeProcesate & vbCrLf & _
           "⏱️ Tempo impiegato: " & Format(tempoFine - tempoInizio, "0.00") & " secondi", vbInformation
    
End Sub

Function TrovaColonne(ws As Worksheet) As Object
    Dim colonne As Object
    Set colonne = CreateObject("Scripting.Dictionary")
    
    Dim ultimaColonna As Long
    Dim i As Long
    Dim nomeColonna As String
    
    ' Trova ultima colonna
    ultimaColonna = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    ' Scansiona la prima riga per trovare i nomi delle colonne
    For i = 1 To ultimaColonna
        nomeColonna = Trim(ws.Cells(1, i).Value)
        
        ' Mappa le colonne necessarie
        Select Case nomeColonna
            Case "Art_Id"
                colonne("Art_Id") = i
            Case "ART_CODICE"
                colonne("ART_CODICE") = i
            Case "classificatore3"
                colonne("classificatore3") = i
            Case "Descrizione"
                colonne("Descrizione") = i
            Case "MARCA"
                colonne("MARCA") = i
            Case "ART_STAGIONE"
                colonne("ART_STAGIONE") = i
            Case "PM_Std"
                colonne("PM_Std") = i
            Case "PM_Std_Data"
                colonne("PM_Std_Data") = i
            Case "PM_T24"
                colonne("PM_T24") = i
            Case "PM_T24_Data"
                colonne("PM_T24_Data") = i
            Case "PM_B2b"
                colonne("PM_B2b") = i
            Case "PM_B2b_Data"
                colonne("PM_B2b_Data") = i
            Case "PM_Collegati"
                colonne("PM_Collegati") = i
            Case "PM_Collegati_Data"
                colonne("PM_Collegati_Data") = i
        End Select
    Next i
    
    Set TrovaColonne = colonne
End Function

Function VerificaColonnePresenti(colonne As Object) As Boolean
    Dim colonneNecessarie As Variant
    Dim i As Long
    
    ' Lista delle colonne obbligatorie
    colonneNecessarie = Array("Art_Id", "ART_CODICE", "classificatore3", "Descrizione", _
                             "MARCA", "ART_STAGIONE", "PM_Std", "PM_Std_Data", _
                             "PM_T24", "PM_T24_Data", "PM_B2b", "PM_B2b_Data", _
                             "PM_Collegati", "PM_Collegati_Data")
    
    ' Verifica che tutte le colonne necessarie siano presenti
    For i = 0 To UBound(colonneNecessarie)
        If Not colonne.Exists(colonneNecessarie(i)) Then
            MsgBox "ERRORE: Colonna mancante: " & colonneNecessarie(i), vbCritical
            VerificaColonnePresenti = False
            Exit Function
        End If
    Next i
    
    VerificaColonnePresenti = True
End Function

Function EstraiRigaCSV(ws As Worksheet, riga As Long, colonne As Object) As String
    Dim campi(13) As String
    Dim i As Long
    Dim valore As Variant
    
    ' Estrai i valori nell'ordine fisso
    campi(0) = PulisciCampoCSV(ws.Cells(riga, colonne("Art_Id")).Value)
    campi(1) = PulisciCampoCSV(ws.Cells(riga, colonne("ART_CODICE")).Value)
    campi(2) = PulisciCampoCSV(ws.Cells(riga, colonne("classificatore3")).Value)
    campi(3) = PulisciCampoCSV(ws.Cells(riga, colonne("Descrizione")).Value)
    campi(4) = PulisciCampoCSV(ws.Cells(riga, colonne("MARCA")).Value)
    campi(5) = PulisciCampoCSV(ws.Cells(riga, colonne("ART_STAGIONE")).Value)
    campi(6) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_Std")).Value)
    campi(7) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_Std_Data")).Value)
    campi(8) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_T24")).Value)
    campi(9) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_T24_Data")).Value)
    campi(10) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_B2b")).Value)
    campi(11) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_B2b_Data")).Value)
    campi(12) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_Collegati")).Value)
    campi(13) = PulisciCampoCSV(ws.Cells(riga, colonne("PM_Collegati_Data")).Value)
    
    ' Unisci i campi con virgole
    EstraiRigaCSV = Join(campi, ",")
End Function

Function PulisciCampoCSV(valore As Variant) As String
    Dim risultato As String
    
    ' Gestisce valori vuoti e nulli
    If IsEmpty(valore) Or IsNull(valore) Then
        PulisciCampoCSV = ""
        Exit Function
    End If
    
    ' Converte in stringa
    risultato = CStr(valore)
    
    ' Gestisce le date
    If IsDate(valore) Then
        risultato = Format(valore, "yyyy-mm-dd hh:mm:ss")
    End If
    
    ' Escape per CSV: racchiude tra virgolette se contiene virgole, virgolette o a capo
    If InStr(risultato, ",") > 0 Or InStr(risultato, """") > 0 Or InStr(risultato, vbCrLf) > 0 Then
        ' Raddoppia le virgolette interne e racchiude tutto tra virgolette
        risultato = """" & Replace(risultato, """", """""") & """"
    End If
    
    PulisciCampoCSV = risultato
End Function

' Funzione di test per verificare le colonne
Sub TestTrovaColonne()
    Dim ws As Worksheet
    Dim colonne As Object
    Dim chiave As Variant
    
    Set ws = ActiveSheet
    Set colonne = TrovaColonne(ws)
    
    Debug.Print "=== COLONNE TROVATE ==="
    For Each chiave In colonne.Keys
        Debug.Print chiave & " -> Colonna " & colonne(chiave)
    Next chiave
    
    Debug.Print "=== VERIFICA COMPLETEZZA ==="
    If VerificaColonnePresenti(colonne) Then
        Debug.Print "✅ Tutte le colonne necessarie sono presenti"
    Else
        Debug.Print "❌ Alcune colonne mancano"
    End If
End Sub 