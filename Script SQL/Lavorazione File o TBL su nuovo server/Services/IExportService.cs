namespace Backend.Services
{
    public interface IExportService
    {
        Task<byte[]> ExportToExcelAsync(string tableName, int? maxRows = null);
        Task<byte[]> ExportToCsvAsync(string tableName, int? maxRows = null);
        Task<string> ExportToJsonAsync(string tableName, int? maxRows = null);
    }
} 