' Variabile globale per passare l'ID al report
Public IdFatturaCorrente As Long

Function CreaPdfBatch07ZR()

    On Error GoTo GestError
    Dim ReportDaStampare As String
    Dim PR1 As Recordset, PR_Documenti As Recordset
    Dim NomePdf As String, Emailcliente As String, Mittente As String, UserMail As String, PasswordMail As String
    Dim NrOrdineT24 As String, TipoOrdineCorrente As String
    Dim ContatorePDF As Integer, ContatoreTotale As Integer
    Dim RispostaUtente As Integer
    
    ' Configurazione email
    Mittente = "noreply@bolognagomme.com"
    UserMail = "noreply@bolognagomme.com"
    PasswordMail = "BolognaGommeBgd"
    
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
            ReportDaStampare = "FatturaAutomatica07ZR"
            
            Do While Not PR1.EOF
                ' Determina il tipo ordine e il percorso PDF
                TipoOrdineCorrente = DeterminaTipoOrdine(NrOrdineT24)
                NomePdf = GeneraPercorsoPDF(TipoOrdineCorrente, NrOrdineT24)
                
                ' Imposta l'ID nella variabile globale invece di Me.
                IdFatturaCorrente = PR1!IdFatture
                
                ' Crea il PDF
                DoCmd.OutputTo acOutputReport, ReportDaStampare, acFormatPDF, NomePdf, False
                ContatorePDF = ContatorePDF + 1
                
                PR1.MoveNext
            Loop
            
        Else
            ' Se non trovato nelle fatture, cerca nelle bolle
            PR1.Close
            Set PR1 = CurrentDb.OpenRecordset("SELECT RicercaBolleWebPortali.* FROM RicercaBolleWebPortali WHERE Descr Like " & "'*" & NrOrdineT24 & "*'", dbOpenDynaset, dbSeeChanges)
            
            If PR1.RecordCount > 0 Then
                ' Documento trovato nelle bolle
                ReportDaStampare = "BollaAutomatica07ZR"
                
                Do While Not PR1.EOF
                    ' Determina il tipo ordine e il percorso PDF
                    TipoOrdineCorrente = DeterminaTipoOrdine(NrOrdineT24)
                    NomePdf = GeneraPercorsoPDF(TipoOrdineCorrente, NrOrdineT24)
                    
                    ' Imposta l'ID nella variabile globale invece di Me.
                    IdFatturaCorrente = PR1!ID
                    
                    ' Crea il PDF
                    DoCmd.OutputTo acOutputReport, ReportDaStampare, acFormatPDF, NomePdf, False
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
        
        ' Chiudi i recordset aperti
        If Not PR1 Is Nothing Then PR1.Close
        If Not PR_Documenti Is Nothing Then PR_Documenti.Close
    End If
End Function

' Funzione ausiliaria per determinare il tipo ordine (da personalizzare secondo le tue regole)
Function DeterminaTipoOrdine(NumeroOrdine As String) As String
    ' Questa funzione dovrebbe contenere la logica per determinare il tipo ordine
    ' basandosi sul numero documento. Per ora restituisco un valore di default
    ' Tu dovrai personalizzarla secondo le tue regole di business
    
    ' Esempi di logica (da adattare):
    If Left(NumeroOrdine, 2) = "DG" Then
        DeterminaTipoOrdine = "07ZR24H"  ' o il tipo appropriato
    ElseIf Left(NumeroOrdine, 2) = "DN" Then
        DeterminaTipoOrdine = "07ZR48H"  ' o il tipo appropriato
    Else
        DeterminaTipoOrdine = "07ZR24H"  ' default
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

' Funzione wrapper per permettere al report di leggere l'ID corrente
Function GetIdFatturaCorrente() As Long
    GetIdFatturaCorrente = IdFatturaCorrente
End Function 