Function CreaPdfBatch07ZR_Semplice()

    On Error GoTo GestError
    Dim PR1 As Recordset, PR_Documenti As Recordset
    Dim NomePdf As String, TipoOrdineCorrente As String
    Dim NrOrdineT24 As String, IdCorrente As Long
    Dim ContatorePDF As Integer, ContatoreTotale As Integer
    Dim RispostaUtente As Integer
    Dim ReportFattura As String, ReportBolla As String
    
    ' Usa i report originali (duplicati senza parametri)
    ReportFattura = "FatturaAutomatica07ZR_Singola"  ' 
    ReportBolla = "BollaAutomatica07ZR_Copy"      ' Duplica il report originale
    
    ContatorePDF = 0
    ContatoreTotale = 0
    
    ' Apertura recordset con i numeri documento da processare
    Set PR_Documenti = CurrentDb.OpenRecordset("SELECT NumeroDocumento FROM Doc_07ZR_perPdf ORDER BY NumeroDocumento", dbOpenDynaset)
    
    If PR_Documenti.RecordCount = 0 Then
        MsgBox "Nessun documento trovato nella tabella Doc_07ZR_perPdf", vbExclamation
        Exit Function
    End If
    
    ' Conferma dall'utente
    RispostaUtente = MsgBox("Trovati " & PR_Documenti.RecordCount & " documenti da processare." & vbCrLf & _
                           "Vuoi procedere con la creazione di tutti i PDF?", _
                           vbQuestion + vbYesNo + vbDefaultButton2, "Conferma Batch PDF")
    
    If RispostaUtente = vbNo Then
        PR_Documenti.Close
        Exit Function
    End If
    
    ' Loop attraverso tutti i numeri documento
    Do While Not PR_Documenti.EOF
        NrOrdineT24 = LTrim(RTrim(PR_Documenti!NumeroDocumento))
        ContatoreTotale = ContatoreTotale + 1
        
        Debug.Print "Processando documento: " & NrOrdineT24 & " (" & ContatoreTotale & " di " & PR_Documenti.RecordCount & ")"
        
        ' Prima cerca nelle fatture
        Set PR1 = CurrentDb.OpenRecordset("SELECT I24TestaFatturePerPdf.*, I24RigheFatturePerPdf.* FROM I24TestaFatturePerPdf INNER JOIN I24RigheFatturePerPdf ON I24TestaFatturePerPdf.IdFatture = I24RigheFatturePerPdf.IdFat WHERE Qta1 = 0 and DescrInFt Like " & "'*" & NrOrdineT24 & "*'", dbOpenDynaset, dbSeeChanges)
        
        If PR1.RecordCount > 0 Then
            ' Documento trovato nelle fatture
            Do While Not PR1.EOF
                TipoOrdineCorrente = DeterminaTipoOrdine(NrOrdineT24)
                NomePdf = GeneraPercorsoPDF(TipoOrdineCorrente, NrOrdineT24)
                IdCorrente = PR1!IdFatture
                
                ' METODO SEMPLICE: Usa filtro WHERE diretto
                Call StampaPdfSemplice(ReportFattura, "I24TestaFatturePerPdf.IdFatture", IdCorrente, NomePdf)
                ContatorePDF = ContatorePDF + 1
                
                PR1.MoveNext
            Loop
            
        Else
            ' Se non trovato nelle fatture, cerca nelle bolle
            PR1.Close
            Set PR1 = CurrentDb.OpenRecordset("SELECT RicercaBolleWebPortali.* FROM RicercaBolleWebPortali WHERE Descr Like " & "'*" & NrOrdineT24 & "*'", dbOpenDynaset, dbSeeChanges)
            
            If PR1.RecordCount > 0 Then
                ' Documento trovato nelle bolle
                Do While Not PR1.EOF
                    TipoOrdineCorrente = DeterminaTipoOrdine(NrOrdineT24)
                    NomePdf = GeneraPercorsoPDF(TipoOrdineCorrente, NrOrdineT24)
                    IdCorrente = PR1!ID
                    
                    ' METODO SEMPLICE: Usa filtro WHERE diretto
                    Call StampaPdfSemplice(ReportBolla, "RicercaBolleWebPortali.ID", IdCorrente, NomePdf)
                    ContatorePDF = ContatorePDF + 1
                    
                    PR1.MoveNext
                Loop
            Else
                Debug.Print "Documento non trovato: " & NrOrdineT24
            End If
        End If
        
        PR1.Close
        PR_Documenti.MoveNext
    Loop
    
    PR_Documenti.Close
    
    ' Messaggio finale
    MsgBox "Processo completato!" & vbCrLf & _
           "Documenti processati: " & ContatoreTotale & vbCrLf & _
           "PDF creati: " & ContatorePDF, vbInformation, "Batch PDF Completato"
    
    Exit Function
    
GestError:
    If Err.Number <> 0 Then
        MsgBox "Errore durante il processo batch: " & Err.Description & vbCrLf & _
               "Documento corrente: " & NrOrdineT24, vbCritical
        
        If Not PR1 Is Nothing Then PR1.Close
        If Not PR_Documenti Is Nothing Then PR_Documenti.Close
    End If
End Function

' Funzione semplificata per stampare PDF con filtro WHERE
Sub StampaPdfSemplice(NomeReport As String, CampoFiltro As String, ValoreId As Long, PercorsoPDF As String)
    
    On Error GoTo ErroreStampa
    
    ' Crea la condizione WHERE semplificata
    Dim CondizioneWhere As String
    
    ' Per report fatture, usa solo il nome campo senza prefisso tabella
    If InStr(NomeReport, "Fattura") > 0 Then
        CondizioneWhere = "IdFatture = " & ValoreId
    Else
        ' Per report bolle
        CondizioneWhere = "ID = " & ValoreId
    End If
    
    Debug.Print "Stampo: " & NomeReport & " con filtro: " & CondizioneWhere
    
    ' Metodo diretto: Apri e stampa in un solo passaggio
    DoCmd.OutputTo acOutputReport, NomeReport, acFormatPDF, PercorsoPDF, False, , , CondizioneWhere
    
    Debug.Print "PDF creato: " & PercorsoPDF
    
    Exit Sub
    
ErroreStampa:
    Debug.Print "ERRORE: " & Err.Description & " - Report: " & NomeReport & " - ID: " & ValoreId
    
    ' Prova un approccio alternativo se il primo fallisce
    Debug.Print "Provo metodo alternativo..."
    
    On Error GoTo ErroreAlternativo
    ' Apri report prima e poi esporta
    DoCmd.OpenReport NomeReport, acViewPreview, , CondizioneWhere
    DoCmd.OutputTo acOutputReport, NomeReport, acFormatPDF, PercorsoPDF, False
    DoCmd.Close acReport, NomeReport
    Debug.Print "PDF creato con metodo alternativo: " & PercorsoPDF
    Exit Sub
    
ErroreAlternativo:
    MsgBox "Errore nella stampa del report " & NomeReport & ": " & Err.Description & vbCrLf & _
           "ID: " & ValoreId & vbCrLf & _
           "Filtro: " & CondizioneWhere, vbCritical
    
    ' Chiudi report se aperto
    On Error Resume Next
    DoCmd.Close acReport, NomeReport
    On Error GoTo 0
End Sub

' Funzione ausiliaria per determinare il tipo ordine
Function DeterminaTipoOrdine(NumeroOrdine As String) As String
    If Left(NumeroOrdine, 2) = "DG" Then
        DeterminaTipoOrdine = "07ZR24H"
    ElseIf Left(NumeroOrdine, 2) = "DN" Then
        DeterminaTipoOrdine = "07ZR48H"
    Else
        DeterminaTipoOrdine = "07ZR24H"
    End If
End Function

' Funzione ausiliaria per generare il percorso PDF
Function GeneraPercorsoPDF(TipoOrdine As String, NumeroOrdine As String) As String
    Dim NomePdf As String
    
    Select Case TipoOrdine
        Case "07ZR24H"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24H\" & NumeroOrdine & ".pdf"
        Case "07ZR48H"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48H\" & NumeroOrdine & ".pdf"
        Case "07ZR72H"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\72H\" & NumeroOrdine & ".pdf"
        Case "07ZR24H_FRA"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24HFRA\" & NumeroOrdine & ".pdf"
        Case "07ZR48H_FRA"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48HFRA\" & NumeroOrdine & ".pdf"
        Case "07ZR_SPA"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\SPA\" & NumeroOrdine & ".pdf"
        Case "07ZR_GER"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\GER\" & NumeroOrdine & ".pdf"
        Case "07ZR_AUS"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\AUS\" & NumeroOrdine & ".pdf"
        Case "07ZR_RicFra"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicFra\" & NumeroOrdine & ".pdf"
        Case "07ZR_RicSpa"
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicSpa\" & NumeroOrdine & ".pdf"
        Case Else
            NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24H\" & NumeroOrdine & ".pdf"
    End Select
    
    GeneraPercorsoPDF = NomePdf
End Function 