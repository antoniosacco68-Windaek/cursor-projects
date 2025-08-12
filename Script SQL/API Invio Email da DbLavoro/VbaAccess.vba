Public Sub SendMessage(strTo As String, strAttachment2 As String, Mittente As String, UserMail As String, PasswordMail As String, Optional Piede As String)
    On Error GoTo GestError
    'Send using the Port on a SMTP server
    Dim attList() As String, TTextBody As String, PR1 As Recordset, CheckLinkPagina As String, TOperatore As String, TLinkPagina As String
    Dim TPiedeEmail As String, LinkChiSiamo As String, FirmaOperatore As String
    Dim TxtRicLinkPag As String, TxtRicLinkDep As String, TLinkPaginaDep As String, CheckLinkPaginaDep As String, TxtRicLinkMec As String, TxtRicLinkRevisione As String
    Dim TLinkPaginaMec As String, TLinkPaginaRevisione As String, CheckLinkPaginaMec As String, CheckLinkPaginaRevisione As String, Operatore As String
    
    CorpoEmail5 = "" ' Azzero il Piede per Gestirlo solo da Qui
   
    
    If CurrentProject.AllForms("PreventivoTesta").IsLoaded = True Then
        'TOperatore = LCase(Forms!PreventivoTesta!PR_Operatore) 'Tutto Minuscolo
        'TOperatore = StrConv(TOperatore, vbProperCase) 'Prima Lettera Maiuscola
        
        ' Gestione della Firma dell'Operatore
        
            'If Forms!PreventivoTesta.Operatore = "ALBA" Then Mittente = "alba.menozzi@bolognagomme.com"
            'If Forms!PreventivoTesta.Operatore = "GABRIELE" Then Mittente = "gabriele.frigato@bolognagomme.com"
        
        CorpoEmail5 = ""
        TPiedeGenerico = "Generico"
        Operatore = Forms!preventivotesta.Operatore
        Pdv = Forms!preventivotesta.PR_Pdv
        
        If Operatore = "ALBA" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "GABRIELE" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Donato" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Mattia" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Dennis" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Eugenio" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "ANDREA Z." Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Andrea M." Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Tania" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Beatrice" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Tiziana" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "FABRIZIO P." Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Nicola" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Costantino" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
        If Operatore = "Davide_Boschi" Then
            Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Operatore & "'", dbOpenDynaset, dbSeeChanges)
            FirmaOperatore = PR1!TestoPiede
            PR1.Close
        End If
    End If
    
    ' Gestione dei Testi da Trasformare in LINK al Sito
    TLinkPagina = "" ' Azzero i Link
    TLinkPaginaDep = "" ' Azzero i Link
    TLinkPaginaMec = "" ' Azzero i Link
    TxtRicLinkPag = "pneumatici" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    TxtRicLinkDep = "deposito" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    TxtRicLinkMec = "meccanica" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    TxtRicLinkRevisione = "revisione" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    TxtRicLinkRicClima = "ricarica clima" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    TxtRicLinkMoto = "moto" ' Testo da Ricercare per diventare un Link alla Pagina Web (devo Riscriverlo sotto nel TLinkPagina)
    
    LinkChiSiamo = "<a href=""http://bolognagomme.eu/chi-siamo/"">Scopri chi siamo</a>" ' Link che aggiungo Nel testo in Fondo per Rimandare al CHI SIAMO del SIto
    
    ' Mail Archivio Punto di Vendita
    If Mittente = "Bg1Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg1team@gmail.com"
        UserMail = Mittente
        PasswordMail = "D)Viz4%w3g0#=oC0<J=z"
    End If
    
    If Mittente = "Bg2Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg2team@gmail.com"
        UserMail = Mittente
        PasswordMail = "Viz4%w3g0#=oC0<J=z"
    End If

    If Mittente = "Bg3Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg3team@gmail.com"
        UserMail = Mittente
        PasswordMail = "BolognaGOmme3"
    End If
    
    If Mittente = "Bg4Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg4team@gmail.com"
        UserMail = Mittente
        PasswordMail = "D)Viz4%w3g0#=oC0<J=z"
    End If
    
    If Mittente = "Bg5Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg5team@gmail.com"
        UserMail = Mittente
        PasswordMail = "xJzvjkLbdkNyLAVKw2FU"
    End If
    
    If Mittente = "Bg6Team@bolognagomme.com" Then
        TPdvArchivio = "archiviobg6team@gmail.com"
        UserMail = Mittente
        PasswordMail = "D)Viz4%w3g0#=oC0<J=z"
    End If
    
    If Mittente = "Bg1Truck@bolognagomme.com" Then
        TPdvArchivio = "archiviobg1team@gmail.com"
        UserMail = "donato.giove@bolognagomme.com"
        Mittente = "donato.giove@bolognagomme.com"
        PasswordMail = "no"
    End If
    
    CheckLinkPagina = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
    If InStr(CheckLinkPagina, TxtRicLinkPag) > 0 Then ' Guardo se c'è scritto "pneumatici" per mettere il Link
        TLinkPagina = "<a href=""https://bolognagomme.eu/pneumatici-e-cerchi/"">pneumatici</a>"
    End If
    CheckLinkPaginaDep = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
    If InStr(CheckLinkPaginaDep, TxtRicLinkDep) > 0 Then ' Guardo se c'è scritto "Allego il volantino" per mettere il Link
        TLinkPaginaDep = "<a href=""https://bolognagomme.eu/servizi/deposito-pneumatici/"">Deposito</a>"
    End If
    CheckLinkPaginaMec = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
    If InStr(CheckLinkPaginaMec, TxtRicLinkMec) > 0 Then ' Guardo se c'è scritto "Allego il volantino" per mettere il Link
        TLinkPaginaMec = "<a href=""https://bolognagomme.eu/meccanica-e-revisioni/"">Meccanica</a>"
    End If
    CheckLinkPaginaRevisione = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
    If InStr(CheckLinkPaginaRevisione, TxtRicLinkRevisione) > 0 Then ' Guardo se c'è scritto "Allego il volantino" per mettere il Link
        TLinkPaginaRevisioni = "<a href=""https://bolognagomme.eu/meccanica-e-revisioni/"">Revisione</a>"
    End If
'    CheckLinkPaginaRicClima = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
'    If InStr(CheckLinkPaginaRicClima, TxtRicLinkRicClima) > 0 Then ' Guardo se c'è scritto "Ricarica clima" per mettere il Link
'        TLinkPaginaRicClima = "<a href=""https://bolognagomme.eu/portfolio-items/promo-ricarica-clima-2019/"">Ricarica clima</a>"
'    End If
'    CheckLinkPaginaMoto = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 ' Stringa con il Testo del Corpo Email
'    If InStr(CheckLinkPaginaMoto, TxtRicLinkMoto) > 0 Then ' Guardo se c'è scritto "moto" per mettere il Link
'        TLinkPaginaMoto = "<a href=""https://bolognagomme.eu/portfolio-items/promo-pneumatici-moto-2019/"">Moto</a>"
'    End If
    
    ' Questo è il Testo da mettere nel piede nella TBL "TestoPiedeEmail"
    ' Visita il nostro sito <a href=""http://www.bolognagomme.com""> www.bolognagomme.com</a>

    If Piede = "Fabiano" Then
        Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & Piede & "'", dbOpenDynaset, dbSeeChanges)
        FirmaOperatore = PR1!TestoPiede
        PR1.Close
    End If
        
    TPiedeGenerico = "Generico" ' Prendo il Piede Generico
    Set PR1 = CurrentDb.OpenRecordset("SELECT TestoPiede FROM TestoPiedeEmail WHERE CodicePiede = " & "'" & TPiedeGenerico & "'", dbOpenDynaset, dbSeeChanges)
        TPiedeEmail = PR1!TestoPiede
    PR1.Close
    
    TTextBody = CorpoEmail1 & CorpoEmail2 & CorpoEmail3 & CorpoEmail4 & vbNewLine & vbNewLine  ' Metto dopo il Piede perché ci sono Frasi che sono anche nei Link e non andava bene
    
    TTextBody = Replace(TTextBody, TxtRicLinkPag, TLinkPagina) ' Mette il Link alla Pagina Web Promo Pneumatici
    TTextBody = Replace(TTextBody, TxtRicLinkDep, TLinkPaginaDep) ' Mette il Link alla Pagina Web Deposito
    TTextBody = Replace(TTextBody, TxtRicLinkMec, TLinkPaginaMec) ' Mette il Link alla Pagina Web Meccanica
    TTextBody = Replace(TTextBody, TxtRicLinkRevisione, TLinkPaginaRevisioni) ' Mette il Link alla Pagina Web Revisioni
    TTextBody = Replace(TTextBody, TxtRicLinkRicClima, TLinkPaginaRicClima) ' Mette il Link alla Pagina Web Ricarica clima
    TTextBody = Replace(TTextBody, TxtRicLinkMoto, TLinkPaginaMoto) ' Mette il Link alla Pagina Web Meccanica
    
    TTextBody = TTextBody & FirmaOperatore & vbNewLine & vbNewLine & TPiedeEmail & vbNewLine & vbNewLine & LinkChiSiamo & vbNewLine & vbNewLine  ' Aggiungo il Piede solo Adesso perchè mi dava Problemi con il link "M"ccanica" nei testi dei Piedi dell'Operatore !!!
    
    TTextBody = Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(TTextBody, Chr(13) & Chr(10), "<br>"), Chr(13) & Chr(10) & Chr(13) & Chr(10), "<br>"), "&", "&amp;"), "€", "&euro;"), "à", "&agrave;"), "è", "&egrave;"), "é", "&eacute;"), "ì", "&igrave;"), "ò", "&ograve;") ' Sistemo i caratteri Speciali
    'TTextBody = Replace(Replace(ttesxtbody, "<br><br>", "<br>"), "<br><br>", "<br>")
    TTextBody = "<!DOCTYPE html><html><head><meta charset=""UTF-8""></head><body>" & vbNewLine & TTextBody & "</body></html>" ' Faccio diventare i campi a CAPO in "<br>" per funzionare in HTHL
    
    Set cn = New ADODB.Connection
    cn.Open "Provider=SQLOLEDB.1;Password=Superboos42s7@#[];Persist Security Info=True;User ID=ant;Initial Catalog=I24DB;Data Source=192.168.100.70;Use Procedure for Prepare=1;Auto Translate=True;Packet Size=4096;Workstation ID=IMPRESA24;Use Encryption for Data=False;Tag with column collation when possible=False"

    Set cmd = New ADODB.Command
    Set cmd.ActiveConnection = cn
    cmd.CommandType = adCmdStoredProc
    cmd.CommandText = "SP_InvioEmailPerDbLavoro" ' Nome della Storage procedure da lanciare
    cmd.Parameters.Append _
        cmd.CreateParameter("@Mittente", adVarChar, adParamInput, 80, Mittente)
    cmd.Parameters.Append _
        cmd.CreateParameter("@StrTo", adVarChar, adParamInput, 200, strTo)
    cmd.Parameters.Append _
        cmd.CreateParameter("@Subject", adVarChar, adParamInput, 200, OggettoEmail + Replace(Replace(strAttachment2, "C:\InvioEmailDb\", " "), ".pdf", ""))
    cmd.Parameters.Append _
        cmd.CreateParameter("@Body", adVarChar, adParamInput, 4000, TTextBody) 'TTextBody
    cmd.Parameters.Append _
        cmd.CreateParameter("@Attachment", adVarChar, adParamInput, 400, strAttachment2) 'strAttachment2
    
    ' Esegue la stored procedure e ottiene il recordset con i risultati
    Dim rs As ADODB.Recordset
    Set rs = cmd.Execute
    
    ' Verifica se l'email è stata inviata con successo controllando il campo "Successo"
    Dim emailInviata As Boolean
    Dim messaggioStato As String
    
    If Not rs.EOF Then
        emailInviata = CBool(rs.Fields("Successo").Value)
        messaggioStato = rs.Fields("Messaggio").Value
    Else
        emailInviata = False
        messaggioStato = "Nessuna risposta dalla procedura di invio email."
    End If
    
    ' Chiude connessione e pulisce oggetti
    Set rs = Nothing
    Set cmd = Nothing
    cn.Close
    Set cn = Nothing
    
    ' Visualizza messaggio appropriato in base allo stato di invio
    If emailInviata Then
        If ReportDaStampare <> "PreventivoSoloAntPromoEmailAutomatico" Then
            MsgBox "Email Inviata con successo!" & vbCrLf & messaggioStato, vbInformation
            DoCmd.Close acForm, "InvioEmail" ' Chiude la Finestra di Invio Email con le Scelte delle Email
        End If
        
        If CurrentProject.AllForms("PreventivoTesta").IsLoaded = True Then Forms!preventivotesta.PR_DataInvioEmail = Now()
    Else
        MsgBox "Errore nell'invio dell'email." & vbCrLf & messaggioStato, vbExclamation
    End If
    
    Exit Sub
    
GestError:
    If Err.Number <> 0 Then
        MsgBox "Errore in Invio. " & Err.Description, vbCritical
    End If
    
    ' Assicura che le risorse vengano liberate anche in caso di errore
    If Not rs Is Nothing Then Set rs = Nothing
    If Not cmd Is Nothing Then Set cmd = Nothing
    If Not cn Is Nothing Then
        If cn.State = adStateOpen Then cn.Close
        Set cn = Nothing
    End If

End Sub