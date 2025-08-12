using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using OfficeOpenXml;
using System.Text;

namespace Backend.Services
{
    public class ExportService : IExportService
    {
        private readonly string _connectionString;
        private readonly ILogger<ExportService> _logger;

        public ExportService(IConfiguration configuration, ILogger<ExportService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        public async Task<byte[]> ExportToExcelAsync(string tableName, int? maxRows = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = $"SELECT * FROM [{tableName}]";
                if (maxRows.HasValue)
                {
                    query += $" ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT {maxRows.Value} ROWS ONLY";
                }

                var data = await connection.QueryAsync(query);
                var dataList = data.ToList();

                using var package = new ExcelPackage();
                var worksheet = package.Workbook.Worksheets.Add(tableName);

                if (dataList.Any())
                {
                    // Intestazioni
                    var columns = ((IDictionary<string, object>)dataList.First()).Keys.ToList();
                    for (int i = 0; i < columns.Count; i++)
                    {
                        worksheet.Cells[1, i + 1].Value = columns[i];
                        worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    }

                    // Dati
                    for (int row = 0; row < dataList.Count; row++)
                    {
                        var rowData = (IDictionary<string, object>)dataList[row];
                        for (int col = 0; col < columns.Count; col++)
                        {
                            worksheet.Cells[row + 2, col + 1].Value = rowData[columns[col]]?.ToString() ?? "";
                        }
                    }

                    worksheet.Cells.AutoFitColumns();
                }

                return await package.GetAsByteArrayAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione Excel tabella: {tableName}");
                throw;
            }
        }

        public async Task<byte[]> ExportToCsvAsync(string tableName, int? maxRows = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = $"SELECT * FROM [{tableName}]";
                if (maxRows.HasValue)
                {
                    query += $" ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT {maxRows.Value} ROWS ONLY";
                }

                var data = await connection.QueryAsync(query);
                var dataList = data.ToList();

                var csv = new StringBuilder();

                if (dataList.Any())
                {
                    // Intestazioni
                    var columns = ((IDictionary<string, object>)dataList.First()).Keys.ToList();
                    csv.AppendLine(string.Join(",", columns.Select(c => $"\"{c}\"")));

                    // Dati
                    foreach (var row in dataList)
                    {
                        var rowData = (IDictionary<string, object>)row;
                        var values = columns.Select(col => $"\"{rowData[col]?.ToString()?.Replace("\"", "\"\"") ?? ""}\"");
                        csv.AppendLine(string.Join(",", values));
                    }
                }

                return Encoding.UTF8.GetBytes(csv.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione CSV tabella: {tableName}");
                throw;
            }
        }

        public async Task<string> ExportToJsonAsync(string tableName, int? maxRows = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = $"SELECT * FROM [{tableName}]";
                if (maxRows.HasValue)
                {
                    query += $" ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT {maxRows.Value} ROWS ONLY";
                }

                var data = await connection.QueryAsync(query);
                return System.Text.Json.JsonSerializer.Serialize(data, new System.Text.Json.JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNamingPolicy = null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione JSON tabella: {tableName}");
                throw;
            }
        }
    }
} 