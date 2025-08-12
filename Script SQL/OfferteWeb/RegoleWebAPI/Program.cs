using Microsoft.Data.SqlClient;
using System.Data;

var builder = WebApplication.CreateBuilder(args);

// Aggiungi servizi
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configura pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseRouting();

// Endpoint per le regole
app.MapGet("/api/regole", async (string? listino = null, string? settore = null) =>
{
    var connectionString = "Server=.;Database=OfferteWeb;Integrated Security=true;TrustServerCertificate=true;";
    
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    
    var sql = @"
        SELECT ID, NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, 
               Settore, RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, 
               MargMenoAS, MargMenoInvernale, DataCreazione, DataModifica
        FROM RegoleListiniDistribuzione 
        WHERE (@Listino IS NULL OR NomeListino = @Listino)
          AND (@Settore IS NULL OR Settore = @Settore)
        ORDER BY NomeListino, Settore, CifraIn";
    
    using var command = new SqlCommand(sql, connection);
    command.Parameters.AddWithValue("@Listino", (object?)listino ?? DBNull.Value);
    command.Parameters.AddWithValue("@Settore", (object?)settore ?? DBNull.Value);
    
    var regole = new List<object>();
    using var reader = await command.ExecuteReaderAsync();
    
    while (await reader.ReadAsync())
    {
        regole.Add(new
        {
            ID = reader.GetInt32("ID"),
            NomeListino = reader.GetString("NomeListino"),
            CifraIn = reader.IsDBNull("CifraIn") ? null : reader.GetDecimal("CifraIn"),
            CifraOut = reader.IsDBNull("CifraOut") ? null : reader.GetDecimal("CifraOut"),
            Margine = reader.IsDBNull("Margine") ? null : reader.GetDecimal("Margine"),
            MargPiu = reader.IsDBNull("MargPiu") ? null : reader.GetDecimal("MargPiu"),
            MargMeno = reader.IsDBNull("MargMeno") ? null : reader.GetDecimal("MargMeno"),
            Settore = reader.GetString("Settore"),
            RicaricoPercentuale = reader.IsDBNull("RicaricoPercentuale") ? null : reader.GetDecimal("RicaricoPercentuale"),
            ProvvPiatt = reader.IsDBNull("ProvvPiatt") ? null : reader.GetDecimal("ProvvPiatt"),
            MargMenoEstivo = reader.IsDBNull("MargMenoEstivo") ? null : reader.GetDecimal("MargMenoEstivo"),
            MargMenoAS = reader.IsDBNull("MargMenoAS") ? null : reader.GetDecimal("MargMenoAS"),
            MargMenoInvernale = reader.IsDBNull("MargMenoInvernale") ? null : reader.GetDecimal("MargMenoInvernale"),
            DataCreazione = reader.GetDateTime("DataCreazione"),
            DataModifica = reader.IsDBNull("DataModifica") ? null : reader.GetDateTime("DataModifica")
        });
    }
    
    return Results.Ok(regole);
});

app.MapPost("/api/regole", async (dynamic regola) =>
{
    var connectionString = "Server=.;Database=OfferteWeb;Integrated Security=true;TrustServerCertificate=true;";
    
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    
    var sql = @"
        INSERT INTO RegoleListiniDistribuzione 
        (NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore, 
         RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, MargMenoAS, MargMenoInvernale,
         CostoTrasportoIt, TipoListForn, DataCreazione, DataModifica)
        VALUES 
        (@NomeListino, @CifraIn, @CifraOut, @Margine, @MargPiu, @MargMeno, @Settore,
         @RicaricoPercentuale, @ProvvPiatt, @MargMenoEstivo, @MargMenoAS, @MargMenoInvernale,
         4.40, '24H', GETDATE(), GETDATE());
        SELECT SCOPE_IDENTITY();";
    
    using var command = new SqlCommand(sql, connection);
    command.Parameters.AddWithValue("@NomeListino", regola.NomeListino ?? "");
    command.Parameters.AddWithValue("@CifraIn", regola.CifraIn ?? DBNull.Value);
    command.Parameters.AddWithValue("@CifraOut", regola.CifraOut ?? DBNull.Value);
    command.Parameters.AddWithValue("@Margine", regola.Margine ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargPiu", regola.MargPiu ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMeno", regola.MargMeno ?? DBNull.Value);
    command.Parameters.AddWithValue("@Settore", regola.Settore ?? "");
    command.Parameters.AddWithValue("@RicaricoPercentuale", regola.RicaricoPercentuale ?? DBNull.Value);
    command.Parameters.AddWithValue("@ProvvPiatt", regola.ProvvPiatt ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoEstivo", regola.MargMenoEstivo ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoAS", regola.MargMenoAS ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoInvernale", regola.MargMenoInvernale ?? DBNull.Value);
    
    var newId = await command.ExecuteScalarAsync();
    return Results.Ok(new { ID = newId, Message = "Regola creata con successo" });
});

app.MapPut("/api/regole/{id}", async (int id, dynamic regola) =>
{
    var connectionString = "Server=.;Database=OfferteWeb;Integrated Security=true;TrustServerCertificate=true;";
    
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    
    var sql = @"
        UPDATE RegoleListiniDistribuzione SET
            NomeListino = @NomeListino,
            CifraIn = @CifraIn,
            CifraOut = @CifraOut,
            Margine = @Margine,
            MargPiu = @MargPiu,
            MargMeno = @MargMeno,
            Settore = @Settore,
            RicaricoPercentuale = @RicaricoPercentuale,
            ProvvPiatt = @ProvvPiatt,
            MargMenoEstivo = @MargMenoEstivo,
            MargMenoAS = @MargMenoAS,
            MargMenoInvernale = @MargMenoInvernale,
            DataModifica = GETDATE()
        WHERE ID = @ID";
    
    using var command = new SqlCommand(sql, connection);
    command.Parameters.AddWithValue("@ID", id);
    command.Parameters.AddWithValue("@NomeListino", regola.NomeListino ?? "");
    command.Parameters.AddWithValue("@CifraIn", regola.CifraIn ?? DBNull.Value);
    command.Parameters.AddWithValue("@CifraOut", regola.CifraOut ?? DBNull.Value);
    command.Parameters.AddWithValue("@Margine", regola.Margine ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargPiu", regola.MargPiu ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMeno", regola.MargMeno ?? DBNull.Value);
    command.Parameters.AddWithValue("@Settore", regola.Settore ?? "");
    command.Parameters.AddWithValue("@RicaricoPercentuale", regola.RicaricoPercentuale ?? DBNull.Value);
    command.Parameters.AddWithValue("@ProvvPiatt", regola.ProvvPiatt ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoEstivo", regola.MargMenoEstivo ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoAS", regola.MargMenoAS ?? DBNull.Value);
    command.Parameters.AddWithValue("@MargMenoInvernale", regola.MargMenoInvernale ?? DBNull.Value);
    
    var rowsAffected = await command.ExecuteNonQueryAsync();
    
    if (rowsAffected > 0)
        return Results.Ok(new { Message = "Regola aggiornata con successo" });
    else
        return Results.NotFound(new { Message = "Regola non trovata" });
});

app.MapDelete("/api/regole/{id}", async (int id) =>
{
    var connectionString = "Server=.;Database=OfferteWeb;Integrated Security=true;TrustServerCertificate=true;";
    
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    
    var sql = "DELETE FROM RegoleListiniDistribuzione WHERE ID = @ID";
    
    using var command = new SqlCommand(sql, connection);
    command.Parameters.AddWithValue("@ID", id);
    
    var rowsAffected = await command.ExecuteNonQueryAsync();
    
    if (rowsAffected > 0)
        return Results.Ok(new { Message = "Regola eliminata con successo" });
    else
        return Results.NotFound(new { Message = "Regola non trovata" });
});

// Endpoint per importare CSV dal percorso predefinito
app.MapPost("/api/import-csv", async () =>
{
    var csvPath = @"C:\Antonio\RegoleB2bPerSoldi\FileDiImportazioneCSV\RegoleListiniDistribuzione.csv";
    
    if (!File.Exists(csvPath))
    {
        return Results.BadRequest(new { Message = "File CSV non trovato nel percorso specificato" });
    }
    
    var connectionString = "Server=.;Database=OfferteWeb;Integrated Security=true;TrustServerCertificate=true;";
    
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    
    try
    {
        var csvContent = await File.ReadAllTextAsync(csvPath);
        var lines = csvContent.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        
        if (lines.Length < 2)
            return Results.BadRequest(new { Message = "File CSV vuoto o malformato" });
        
        var headers = lines[0].Split(';');
        var imported = 0;
        
        for (int i = 1; i < lines.Length; i++)
        {
            var values = lines[i].Split(';');
            if (values.Length < headers.Length) continue;
            
            var sql = @"
                INSERT INTO RegoleListiniDistribuzione 
                (NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore, 
                 RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, MargMenoAS, MargMenoInvernale,
                 CostoTrasportoIt, TipoListForn, DataCreazione, DataModifica)
                VALUES 
                (@NomeListino, @CifraIn, @CifraOut, @Margine, @MargPiu, @MargMeno, @Settore,
                 @RicaricoPercentuale, @ProvvPiatt, @MargMenoEstivo, @MargMenoAS, @MargMenoInvernale,
                 4.40, '24H', GETDATE(), GETDATE())";
            
            using var command = new SqlCommand(sql, connection);
            
            // Mappa i valori CSV ai parametri
            command.Parameters.AddWithValue("@NomeListino", GetCsvValue(values, 1));
            command.Parameters.AddWithValue("@CifraIn", ParseDecimal(GetCsvValue(values, 2)));
            command.Parameters.AddWithValue("@CifraOut", ParseDecimal(GetCsvValue(values, 3)));
            command.Parameters.AddWithValue("@Margine", ParseDecimal(GetCsvValue(values, 4)));
            command.Parameters.AddWithValue("@MargPiu", ParseDecimal(GetCsvValue(values, 5)));
            command.Parameters.AddWithValue("@MargMeno", ParseDecimal(GetCsvValue(values, 6)));
            command.Parameters.AddWithValue("@Settore", GetCsvValue(values, 7));
            command.Parameters.AddWithValue("@RicaricoPercentuale", ParseDecimal(GetCsvValue(values, 8)));
            command.Parameters.AddWithValue("@ProvvPiatt", ParseDecimal(GetCsvValue(values, 9)));
            command.Parameters.AddWithValue("@MargMenoEstivo", ParseDecimal(GetCsvValue(values, 10)));
            command.Parameters.AddWithValue("@MargMenoAS", ParseDecimal(GetCsvValue(values, 11)));
            command.Parameters.AddWithValue("@MargMenoInvernale", ParseDecimal(GetCsvValue(values, 12)));
            
            await command.ExecuteNonQueryAsync();
            imported++;
        }
        
        return Results.Ok(new { Message = $"Importate {imported} regole dal CSV", ImportedCount = imported });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { Message = "Errore durante l'importazione: " + ex.Message });
    }
});

// Funzioni helper
static string GetCsvValue(string[] values, int index)
{
    if (index >= values.Length) return "";
    var value = values[index].Trim().Trim('"');
    return value == "null" ? "" : value;
}

static object ParseDecimal(string value)
{
    if (string.IsNullOrEmpty(value) || value == "null")
        return DBNull.Value;
    
    if (decimal.TryParse(value, out decimal result))
        return result;
    
    return DBNull.Value;
}

// Endpoint per file statici (serve l'interfaccia HTML)
app.UseStaticFiles();

app.Run(); 