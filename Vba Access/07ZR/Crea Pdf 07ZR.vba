Function CreaPdfFattura07ZR()

    On Error GoTo GestError
    Dim ReportDaStampare As String
    Dim NFatIn As Integer, NFatOut As Integer, DFatIn As Long, DFatOut As Long, Anno As Integer, TTipDoc As Long, TipoDocumento As String, NrOrdineT24 As String
    Dim PR1 As Recordset
    Dim NomePdf As String, Emailcliente As String, Mittente As String, UserMail As String, PasswordMail As String, OggettoEmail As String, CorpoEmail As String
    
    Mittente = "noreply@bolognagomme.com"
    UserMail = "noreply@bolognagomme.com"
    PasswordMail = "BolognaGommeBgd"
    'Shell "cmd.exe /c del C:\InvioEmailDb\07ZR\*.pdf", vbNormalFocus
    
    Me.IdFatturaPerStampa = Null
    NrOrdineT24 = LTrim(RTrim(Me.TOrdineNr))
    
    Set PR1 = CurrentDb.OpenRecordset("SELECT I24TestaFatturePerPdf.*, I24RigheFatturePerPdf.* FROM I24TestaFatturePerPdf INNER JOIN I24RigheFatturePerPdf ON I24TestaFatturePerPdf.IdFatture = I24RigheFatturePerPdf.IdFat WHERE Qta1 = 0 and DescrInFt Like " & "'*" & NrOrdineT24 & "*'", dbOpenDynaset, dbSeeChanges)
    
    ReportDaStampare = "FatturaAutomatica07ZR"
    T = PR1.RecordCount
    If T > 0 Then
    
        Do While Not PR1.EOF
            Me.IdFatturaPerStampa = PR1!IdFatture
            'Shell "cmd.exe /c del C:\InvioEmailDb\07ZR\*.pdf", vbNormalFocus
            If Me.TipoOrdine = "07ZR24H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR48H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR72H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\72H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR24H_FRA" Then NomePdf = "C:\InvioEmailDB\07ZR\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR48H_FRA" Then NomePdf = "C:\InvioEmailDB\07ZR\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR24H_FRA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24HFRA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR48H_FRA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48HFRA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR_SPA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\SPA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR_GER" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\GER\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR_AUS" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\AUS\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR_RicFra" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicFra\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            If Me.TipoOrdine = "07ZR_RicSpa" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicSpa\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
            
            DoCmd.OutputTo acOutputReport, ReportDaStampare, acFormatPDF, NomePdf, False
            DoCmd.OpenReport ReportDaStampare, acViewPreview, , , acDialog
    
            PR1.MoveNext
        Loop
    Else
        PR1.Close
        Set PR1 = CurrentDb.OpenRecordset("SELECT RicercaBolleWebPortali.* FROM RicercaBolleWebPortali WHERE Descr Like " & "'*" & NrOrdineT24 & "*'", dbOpenDynaset, dbSeeChanges)
    
        ReportDaStampare = "BollaAutomatica07ZR"
        T = PR1.RecordCount
        If T > 0 Then
        
            Do While Not PR1.EOF
                Me.IdFatturaPerStampa = PR1!ID
                'Shell "cmd.exe /c del C:\InvioEmailDb\07ZR\*.pdf", vbNormalFocus
                If Me.TipoOrdine = "07ZR24H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR48H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR72H" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\72H\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR24H_FRA" Then NomePdf = "C:\InvioEmailDB\07ZR\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR48H_FRA" Then NomePdf = "C:\InvioEmailDB\07ZR\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR24H_FRA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\24HFRA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR48H_FRA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\48HFRA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR_SPA" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\SPA\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR_GER" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\GER\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR_AUS" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\AUS\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR_RicFra" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicFra\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                If Me.TipoOrdine = "07ZR_RicSpa" Then NomePdf = "C:\Antonio\Propneus(07ZR)\Invio\Invoices\RicSpa\" & LTrim(RTrim(NrOrdineT24)) & ".pdf"
                
                DoCmd.OutputTo acOutputReport, ReportDaStampare, acFormatPDF, NomePdf, False
                DoCmd.OpenReport ReportDaStampare, acViewPreview, , , acDialog
        
                PR1.MoveNext
            Loop
        Else
            MsgBox ("Nessuna Bolla/Fattura Trovata in I24")
            End
        End If
    End If
    
    PR1.Close
        
GestError:
If Err.Number <> 0 Then

    MsgBox "Errore Preparazione PDF. " & Err.Description

Else

    OggettoEmail = "Fattura Ordine Nr: " & Me.TOrdineNr
    CorpoEmail = OggettoEmail
    
    If Not IsNull(Me.EMAIL) Then
        Emailcliente = Me.EMAIL
    End If
    
    ' Se vedo che il Tuipo di Ordine è Francese Cambio la Mail a cui inviare Invoice
    If Me.TipoOrdine Like "*Fra*" Then Emailcliente = "compta@distri2b.com"
    
    If MsgBox("Il Documento era Corretto lo Vuoi Inviare ??", vbInformation + vbYesNo + vbDefaultButton2) = vbNo Then End
        
    Call SendMessage(Emailcliente, NomePdf, Mittente, UserMail, PasswordMail, OggettoEmail, CorpoEmail) ' Chiamata alla funzione
    
    MsgBox ("Email Della Fattura Inviata al Cliente !"), vbInformation
    
    Shell "cmd.exe /c del C:\InvioEmailDB\07ZR\*.*", vbHide
    
End If



End Function