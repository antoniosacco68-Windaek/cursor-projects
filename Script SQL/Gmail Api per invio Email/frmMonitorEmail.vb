Option Compare Database
Option Explicit

Private emailID As String
Private timerCount As Integer

' Questa funzione controlla lo stato dell'email nel database
Private Function ControllaStatoEmail(ID As String) As String
    On Error GoTo GestError
    
    If ID = "" Then
        ControllaStatoEmail = "Errore|ID email non valido|"
        Exit Function
    End If
    
    Dim cn As ADODB.Connection
    Dim cmd As ADODB.Command
    Dim rs As ADODB.Recordset
    
    Set cn = New ADODB.Connection
    cn.Open "Provider=SQLOLEDB.1;Password=Superboos42s7@#[];Persist Security Info=True;User ID=ant;Initial Catalog=I24DB;Data Source=192.168.100.70"
    
    Set cmd = New ADODB.Command
    Set cmd.ActiveConnection = cn
    cmd.CommandType = adCmdText
    cmd.CommandText = "SELECT StatoElaborazione, Note, DataInvio FROM EmailData WHERE ID = ?"
    cmd.Parameters.Append cmd.CreateParameter("EmailID_param", adVarChar, adParamInput, 50, ID)
    
    Set rs = cmd.Execute
    
    If Not rs.EOF Then
        Dim stato As String
        Dim note As String
        Dim dataInvio As Variant
        
        stato = IIf(IsNull(rs("StatoElaborazione")), "In Attesa", rs("StatoElaborazione").Value)
        note = IIf(IsNull(rs("Note")), "", rs("Note").Value)
        dataInvio = IIf(IsNull(rs("DataInvio")), "", rs("DataInvio").Value)
        
        ControllaStatoEmail = stato & "|" & note & "|" & dataInvio
    Else
        ControllaStatoEmail = "Non Trovata||"
    End If
    
    rs.Close
    cn.Close
    Set rs = Nothing
    Set cmd = Nothing
    Set cn = Nothing
    
    Exit Function
    
GestError:
    ControllaStatoEmail = "Errore|" & Err.Description & "|"
    
    If Not rs Is Nothing Then Set rs = Nothing
    If Not cmd Is Nothing Then Set cmd = Nothing
    If Not cn Is Nothing Then
        If cn.State = adStateOpen Then cn.Close
        Set cn = Nothing
    End If
End Function

Private Sub Form_Load()
    ' Ottieni l'ID dell'email passato come parametro
    emailID = Nz(Me.OpenArgs, "")
    
    ' Verifica che l'ID non sia nullo
    If Len(emailID) = 0 Then
        MsgBox "Errore: ID email non valido", vbCritical
        DoCmd.Close acForm, Me.Name
        Exit Sub
    End If
    
    ' Imposta l'ID dell'email nella form
    Me.txtEmailID = emailID
    Me.txtStato = "In Coda"
    Me.txtTimestamp = Now()
    
    ' Avvia il timer
    timerCount = 0
    Me.TimerInterval = 3000 ' 3 secondi
End Sub

Private Sub Form_Timer()
    ' Verifica che l'ID email sia valido
    If Len(emailID) = 0 Then
        Me.TimerInterval = 0
        Me.txtStato = "Errore"
        Me.txtNote = "ID email non valido"
        Exit Sub
    End If
    
    ' Aggiorna il contatore
    timerCount = timerCount + 1
    
    ' Aggiorna le informazioni di stato
    Dim statoInfo As String
    statoInfo = ControllaStatoEmail(emailID)
    
    ' Separa le informazioni
    Dim parti() As String
    parti = Split(statoInfo, "|")
    
    ' Aggiorna i campi della form
    Me.txtStato = parti(0)
    Me.txtNote = parti(1)
    
    If parti(2) <> "" Then
        Me.txtTimestamp = CDate(parti(2))
    End If
    
    ' Aggiorna la barra di progresso
    Select Case Me.txtStato
        Case "In Coda"
            Me.txtProgresso = "10%"
        Case "In Elaborazione"
            Me.txtProgresso = "50%"
        Case "Completata"
            Me.txtProgresso = "100%"
        Case "Errore"
            Me.txtProgresso = "100%"
        Case Else
            Me.txtProgresso = "0%"
    End Select
    
    ' Gestione completamento
    If Me.txtStato = "Completata" Then
        Me.TimerInterval = 0 ' Ferma il timer
        MsgBox "L'email è stata inviata con successo!", vbInformation
        DoCmd.Close acForm, Me.Name
    ElseIf Me.txtStato = "Errore" Then
        Me.TimerInterval = 0 ' Ferma il timer
        MsgBox "Si è verificato un errore durante l'invio dell'email:" & vbCrLf & Me.txtNote, vbExclamation
        ' Non chiudere la form in caso di errore per permettere all'utente di vedere i dettagli
    ElseIf timerCount > 60 Then ' Dopo 3 minuti (60 * 3 secondi)
        Me.TimerInterval = 0 ' Ferma il timer
        Me.cmdControlla.Enabled = True ' Abilita il pulsante per controllo manuale
        MsgBox "L'invio dell'email sta richiedendo più tempo del previsto." & vbCrLf & _
               "Puoi attendere o controllare lo stato più tardi.", vbInformation
    End If
End Sub

Private Sub cmdControlla_Click()
    ' Ricontrolla manualmente lo stato
    Form_Timer
End Sub

Private Sub cmdChiudi_Click()
    ' Chiudi la form
    DoCmd.Close acForm, Me.Name
End Sub 