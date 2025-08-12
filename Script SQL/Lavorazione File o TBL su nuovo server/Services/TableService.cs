using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Backend.Services;

namespace Backend.Services
{
    public class TableService : ITableService
    {
        private readonly string _connectionString;
        private readonly ILogger<TableService> _logger;

        public TableService(IConfiguration configuration, ILogger<TableService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
        }

        public async Task<IEnumerable<string>> GetTableNamesAsync()
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT TABLE_NAME 
                    FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_TYPE = 'BASE TABLE' 
                    ORDER BY TABLE_NAME";
                
                var tables = await connection.QueryAsync<string>(query);
                return tables;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero nomi tabelle");
                return Enumerable.Empty<string>();
            }
        }

        public async Task<IEnumerable<dynamic>> GetTableDataAsync(string tableName, int page = 1, int pageSize = 50)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var offset = (page - 1) * pageSize;
                var query = $@"
                    SELECT * 
                    FROM [{tableName}] 
                    ORDER BY (SELECT NULL)
                    OFFSET {offset} ROWS 
                    FETCH NEXT {pageSize} ROWS ONLY";
                
                var data = await connection.QueryAsync(query);
                return data;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero dati tabella: {tableName}");
                return Enumerable.Empty<dynamic>();
            }
        }

        public async Task<int> GetTableRowCountAsync(string tableName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = $"SELECT COUNT(*) FROM [{tableName}]";
                var count = await connection.ExecuteScalarAsync<int>(query);
                return count;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante conteggio righe tabella: {tableName}");
                return 0;
            }
        }

        public async Task<IEnumerable<dynamic>> GetTableSchemaAsync(string tableName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT 
                        COLUMN_NAME,
                        DATA_TYPE,
                        IS_NULLABLE,
                        COLUMN_DEFAULT,
                        CHARACTER_MAXIMUM_LENGTH
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_NAME = @TableName 
                    ORDER BY ORDINAL_POSITION";
                
                var schema = await connection.QueryAsync(query, new { TableName = tableName });
                return schema;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero schema tabella: {tableName}");
                return Enumerable.Empty<dynamic>();
            }
        }

        public async Task<bool> TableExistsAsync(string tableName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT COUNT(*) 
                    FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_NAME = @TableName";
                
                var count = await connection.ExecuteScalarAsync<int>(query, new { TableName = tableName });
                return count > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante verifica esistenza tabella: {tableName}");
                return false;
            }
        }

        public async Task<int> InsertRecordAsync(string tableName, Dictionary<string, object> record)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var columns = string.Join(", ", record.Keys.Select(k => $"[{k}]"));
                var values = string.Join(", ", record.Keys.Select(k => $"@{k}"));
                var query = $"INSERT INTO [{tableName}] ({columns}) VALUES ({values})";
                
                var affectedRows = await connection.ExecuteAsync(query, record);
                return affectedRows;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante inserimento record in tabella: {tableName}");
                throw;
            }
        }

        public async Task<int> UpdateRecordAsync(string tableName, Dictionary<string, object> whereClause, Dictionary<string, object> newValues)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var setClause = string.Join(", ", newValues.Keys.Select(k => $"[{k}] = @{k}"));
                var whereClauseStr = string.Join(" AND ", whereClause.Keys.Select(k => $"[{k}] = @where_{k}"));
                var query = $"UPDATE [{tableName}] SET {setClause} WHERE {whereClauseStr}";
                
                var parameters = new DynamicParameters();
                foreach (var kvp in newValues)
                {
                    parameters.Add(kvp.Key, kvp.Value);
                }
                foreach (var kvp in whereClause)
                {
                    parameters.Add($"where_{kvp.Key}", kvp.Value);
                }
                
                var affectedRows = await connection.ExecuteAsync(query, parameters);
                return affectedRows;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante aggiornamento record in tabella: {tableName}");
                throw;
            }
        }

        public async Task<int> DeleteRecordAsync(string tableName, Dictionary<string, object> whereClause)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var whereClauseStr = string.Join(" AND ", whereClause.Keys.Select(k => $"[{k}] = @{k}"));
                var query = $"DELETE FROM [{tableName}] WHERE {whereClauseStr}";
                
                var affectedRows = await connection.ExecuteAsync(query, whereClause);
                return affectedRows;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante eliminazione record in tabella: {tableName}");
                throw;
            }
        }

        public async Task<IEnumerable<dynamic>> ExecuteCustomQueryAsync(string tableName, string query, Dictionary<string, object>? parameters = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var result = await connection.QueryAsync(query, parameters);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esecuzione query personalizzata in tabella: {tableName}");
                throw;
            }
        }

        public async Task<string?> GetPrimaryKeyColumnAsync(string tableName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT COLUMN_NAME
                    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                    WHERE TABLE_NAME = @TableName 
                    AND CONSTRAINT_NAME LIKE 'PK_%'";
                
                var primaryKey = await connection.QueryFirstOrDefaultAsync<string>(query, new { TableName = tableName });
                return primaryKey;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero chiave primaria tabella: {tableName}");
                return null;
            }
        }
    }
} 