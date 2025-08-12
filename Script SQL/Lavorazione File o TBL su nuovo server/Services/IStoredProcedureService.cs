namespace Backend.Services
{
    public interface IStoredProcedureService
    {
        Task<IEnumerable<string>> GetStoredProcedureNamesAsync();
        Task<IEnumerable<dynamic>> ExecuteStoredProcedureAsync(string procedureName, Dictionary<string, object>? parameters = null);
        Task<bool> StoredProcedureExistsAsync(string procedureName);
        Task<IEnumerable<dynamic>> GetStoredProcedureParametersAsync(string procedureName);
        Task<IEnumerable<dynamic>> ExecuteCustomQueryAsync(string query, Dictionary<string, object>? parameters = null);
        Task<dynamic> GetDatabaseInfoAsync();
        Task<IEnumerable<dynamic>> GetTablesInfoAsync();
    }
} 