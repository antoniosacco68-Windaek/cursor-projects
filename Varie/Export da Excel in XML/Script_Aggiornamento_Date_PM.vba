Private Sub Worksheet_Change(ByVal Target As Range)
    ' Script per aggiornare automaticamente le date quando vengono modificati i prezzi manuali
    ' Funziona dinamicamente con i nomi delle colonne, indipendentemente dalla loro posizione
    
    Dim ws As Worksheet
    Dim headerRow As Long
    Dim lastRow As Long
    Dim lastCol As Long
    Dim col As Long
    Dim headerName As String
    Dim dateColumnName As String
    Dim dateColumn As Long
    Dim priceColumns As Collection
    Dim priceColumn As Variant
    
    ' Imposta il foglio di lavoro corrente
    Set ws = Me
    headerRow = 1 ' Riga delle intestazioni
    
    ' Se la modifica è sulla riga delle intestazioni, non fare nulla
    If Target.Row = headerRow Then Exit Sub
    
    ' Trova l'ultima riga e colonna con dati
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(headerRow, ws.Columns.Count).End(xlToLeft).Column
    
    ' Crea una collezione per memorizzare le colonne dei prezzi manuali
    Set priceColumns = New Collection
    
    ' Scansiona tutte le colonne per trovare quelle che iniziano con "PM_"
    For col = 1 To lastCol
        headerName = UCase(Trim(ws.Cells(headerRow, col).Value))
        
        ' Controlla se è una colonna di prezzo manuale (inizia con "PM_" e non finisce con "_DATA")
        If Left(headerName, 3) = "PM_" And Right(headerName, 5) <> "_DATA" Then
            ' Aggiungi alla collezione: Key = nome colonna, Item = numero colonna
            priceColumns.Add col, headerName
        End If
    Next col
    
    ' Controlla se la cella modificata è in una delle colonne dei prezzi manuali
    For Each priceColumn In priceColumns
        col = priceColumn
        
        ' Verifica se la modifica è in questa colonna prezzo
        If Not Application.Intersect(Target, ws.Columns(col)) Is Nothing Then
            ' Ottieni il nome della colonna prezzo
            headerName = UCase(Trim(ws.Cells(headerRow, col).Value))
            
            ' Costruisci il nome della colonna data corrispondente
            dateColumnName = headerName & "_DATA"
            
            ' Trova la colonna data corrispondente
            dateColumn = FindColumnByName(ws, dateColumnName, headerRow, lastCol)
            
            If dateColumn > 0 Then
                ' Aggiorna la data per ogni riga modificata
                Dim cell As Range
                For Each cell In Target
                    If cell.Column = col And cell.Row > headerRow And cell.Row <= lastRow Then
                        ' Controlla il valore della cella
                        If IsEmpty(cell.Value) Or cell.Value = "" Or cell.Value = 0 Then
                            ' Se il valore è vuoto, stringa vuota o zero, cancella la data
                            ws.Cells(cell.Row, dateColumn).Value = ""
                        Else
                            ' Se il valore è valido, aggiorna la data
                            ws.Cells(cell.Row, dateColumn).Value = Date
                        End If
                    End If
                Next cell
            End If
        End If
    Next priceColumn
    
    ' Pulisci gli oggetti
    Set priceColumns = Nothing
    Set ws = Nothing
End Sub

' Funzione helper per trovare una colonna per nome
Private Function FindColumnByName(ws As Worksheet, columnName As String, headerRow As Long, lastCol As Long) As Long
    Dim col As Long
    Dim headerValue As String
    
    FindColumnByName = 0 ' Valore predefinito se non trova la colonna
    
    For col = 1 To lastCol
        headerValue = UCase(Trim(ws.Cells(headerRow, col).Value))
        If headerValue = UCase(columnName) Then
            FindColumnByName = col
            Exit Function
        End If
    Next col
End Function

' Procedura per testare il funzionamento (opzionale)
Sub TestPMColumns()
    Dim ws As Worksheet
    Dim headerRow As Long
    Dim lastCol As Long
    Dim col As Long
    Dim headerName As String
    Dim dateColumnName As String
    Dim dateColumn As Long
    Dim message As String
    
    Set ws = ActiveSheet
    headerRow = 1
    lastCol = ws.Cells(headerRow, ws.Columns.Count).End(xlToLeft).Column
    
    message = "Colonne PM_ trovate e le loro corrispondenti colonne data:" & vbCrLf & vbCrLf
    
    For col = 1 To lastCol
        headerName = UCase(Trim(ws.Cells(headerRow, col).Value))
        
        If Left(headerName, 3) = "PM_" And Right(headerName, 5) <> "_DATA" Then
            dateColumnName = headerName & "_DATA"
            dateColumn = FindColumnByName(ws, dateColumnName, headerRow, lastCol)
            
            If dateColumn > 0 Then
                message = message & "✓ " & headerName & " (Col " & col & ") → " & dateColumnName & " (Col " & dateColumn & ")" & vbCrLf
            Else
                message = message & "✗ " & headerName & " (Col " & col & ") → " & dateColumnName & " (NON TROVATA)" & vbCrLf
            End If
        End If
    Next col
    
    MsgBox message, vbInformation, "Test Colonne PM_"
End Sub

' Procedura per abilitare/disabilitare l'aggiornamento automatico
Sub AbilitaAggiornamentoAutomatico()
    Application.EnableEvents = True
    MsgBox "Aggiornamento automatico delle date PM_ ABILITATO", vbInformation
End Sub

Sub DisabilitaAggiornamentoAutomatico()
    Application.EnableEvents = False
    MsgBox "Aggiornamento automatico delle date PM_ DISABILITATO", vbWarning
End Sub

' Procedura di test per verificare il comportamento con diversi valori
Sub TestComportamentoDate()
    Dim ws As Worksheet
    Dim headerRow As Long
    Dim lastCol As Long
    Dim col As Long
    Dim headerName As String
    Dim dateColumn As Long
    Dim testRow As Long
    Dim message As String
    
    Set ws = ActiveSheet
    headerRow = 1
    lastCol = ws.Cells(headerRow, ws.Columns.Count).End(xlToLeft).Column
    testRow = 2 ' Usa la riga 2 per i test
    
    message = "Test del comportamento delle date PM_:" & vbCrLf & vbCrLf
    
    ' Trova la prima colonna PM_ per il test
    For col = 1 To lastCol
        headerName = UCase(Trim(ws.Cells(headerRow, col).Value))
        
        If Left(headerName, 3) = "PM_" And Right(headerName, 5) <> "_DATA" Then
            dateColumn = FindColumnByName(ws, headerName & "_DATA", headerRow, lastCol)
            
            If dateColumn > 0 Then
                message = message & "Test su colonna: " & headerName & vbCrLf
                message = message & "Colonna data: " & headerName & "_DATA" & vbCrLf & vbCrLf
                
                ' Disabilita eventi per evitare loop
                Application.EnableEvents = False
                
                ' Test 1: Inserisci un valore valido
                ws.Cells(testRow, col).Value = 25.50
                Application.EnableEvents = True
                ws.Cells(testRow, col).Value = 25.50 ' Trigger dell'evento
                Application.EnableEvents = False
                message = message & "✓ Valore 25.50 → Data: " & ws.Cells(testRow, dateColumn).Value & vbCrLf
                
                ' Test 2: Inserisci 0
                Application.EnableEvents = True
                ws.Cells(testRow, col).Value = 0 ' Trigger dell'evento
                Application.EnableEvents = False
                message = message & "✓ Valore 0 → Data: """ & ws.Cells(testRow, dateColumn).Value & """" & vbCrLf
                
                ' Test 3: Svuota la cella
                Application.EnableEvents = True
                ws.Cells(testRow, col).Value = "" ' Trigger dell'evento
                Application.EnableEvents = False
                message = message & "✓ Cella vuota → Data: """ & ws.Cells(testRow, dateColumn).Value & """" & vbCrLf
                
                ' Ripristina eventi
                Application.EnableEvents = True
                
                Exit For ' Testa solo la prima colonna PM_ trovata
            End If
        End If
    Next col
    
    If col > lastCol Then
        message = "❌ Nessuna colonna PM_ trovata per il test"
    End If
    
    MsgBox message, vbInformation, "Test Comportamento Date PM_"
End Sub 