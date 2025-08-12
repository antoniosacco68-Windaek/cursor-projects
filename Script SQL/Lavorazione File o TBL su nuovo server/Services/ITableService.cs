using Backend.Models;

namespace Backend.Services
{
    public interface ITableService
    {
        Task<IEnumerable<string>> GetTableNamesAsync();
        Task<IEnumerable<dynamic>> GetTableDataAsync(string tableName, int page = 1, int pageSize = 50);
        Task<int> GetTableRowCountAsync(string tableName);
        Task<IEnumerable<dynamic>> GetTableSchemaAsync(string tableName);
        Task<bool> TableExistsAsync(string tableName);
        Task<int> InsertRecordAsync(string tableName, Dictionary<string, object> record);
        Task<int> UpdateRecordAsync(string tableName, Dictionary<string, object> whereClause, Dictionary<string, object> newValues);
        Task<int> DeleteRecordAsync(string tableName, Dictionary<string, object> whereClause);
        Task<IEnumerable<dynamic>> ExecuteCustomQueryAsync(string tableName, string query, Dictionary<string, object>? parameters = null);
        Task<string?> GetPrimaryKeyColumnAsync(string tableName);
    }

    public class TableDataRequest
    {
        public string TableName { get; set; } = string.Empty;
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 50;
        public string? SortColumn { get; set; }
        public string? SortDirection { get; set; }
        public string? FilterColumn { get; set; }
        public string? FilterValue { get; set; }
    }
} 