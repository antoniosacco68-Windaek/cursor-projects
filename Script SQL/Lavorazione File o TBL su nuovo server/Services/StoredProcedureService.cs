using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Backend.Services
{
    public class StoredProcedureService : IStoredProcedureService
    {
        private readonly string _connectionString;
        private readonly ILogger<StoredProcedureService> _logger;

        public StoredProcedureService(IConfiguration configuration, ILogger<StoredProcedureService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
        }

        public async Task<IEnumerable<string>> GetStoredProcedureNamesAsync()
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT ROUTINE_NAME 
                    FROM INFORMATION_SCHEMA.ROUTINES 
                    WHERE ROUTINE_TYPE = 'PROCEDURE' 
                    ORDER BY ROUTINE_NAME";
                
                var procedures = await connection.QueryAsync<string>(query);
                return procedures;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero nomi stored procedure");
                return Enumerable.Empty<string>();
            }
        }

        public async Task<IEnumerable<dynamic>> ExecuteStoredProcedureAsync(string procedureName, Dictionary<string, object>? parameters = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var dynamicParams = new DynamicParameters();
                
                if (parameters != null)
                {
                    foreach (var param in parameters)
                    {
                        dynamicParams.Add(param.Key, param.Value);
                    }
                }

                var result = await connection.QueryAsync(procedureName, dynamicParams, commandType: System.Data.CommandType.StoredProcedure);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esecuzione stored procedure: {procedureName}");
                return Enumerable.Empty<dynamic>();
            }
        }

        public async Task<bool> StoredProcedureExistsAsync(string procedureName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT COUNT(*) 
                    FROM INFORMATION_SCHEMA.ROUTINES 
                    WHERE ROUTINE_TYPE = 'PROCEDURE' 
                    AND ROUTINE_NAME = @ProcedureName";
                
                var count = await connection.ExecuteScalarAsync<int>(query, new { ProcedureName = procedureName });
                return count > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante verifica esistenza stored procedure: {procedureName}");
                return false;
            }
        }

        public async Task<IEnumerable<dynamic>> GetStoredProcedureParametersAsync(string procedureName)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT 
                        PARAMETER_NAME,
                        PARAMETER_MODE,
                        DATA_TYPE,
                        IS_NULLABLE,
                        PARAMETER_DEFAULT
                    FROM INFORMATION_SCHEMA.PARAMETERS 
                    WHERE SPECIFIC_NAME = @ProcedureName 
                    ORDER BY ORDINAL_POSITION";
                
                var parameters = await connection.QueryAsync(query, new { ProcedureName = procedureName });
                return parameters;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero parametri stored procedure: {procedureName}");
                return Enumerable.Empty<dynamic>();
            }
        }

        public async Task<IEnumerable<dynamic>> ExecuteCustomQueryAsync(string query, Dictionary<string, object>? parameters = null)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var result = await connection.QueryAsync(query, parameters);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante esecuzione query personalizzata");
                throw;
            }
        }

        public async Task<dynamic> GetDatabaseInfoAsync()
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT 
                        DB_NAME() as DatabaseName,
                        DATABASEPROPERTYEX(DB_NAME(), 'Status') as Status,
                        DATABASEPROPERTYEX(DB_NAME(), 'Recovery') as RecoveryModel,
                        DATABASEPROPERTYEX(DB_NAME(), 'IsAutoClose') as IsAutoClose,
                        DATABASEPROPERTYEX(DB_NAME(), 'IsAutoShrink') as IsAutoShrink,
                        DATABASEPROPERTYEX(DB_NAME(), 'IsFulltextEnabled') as IsFulltextEnabled";
                
                var info = await connection.QueryFirstAsync(query);
                return info;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero informazioni database");
                throw;
            }
        }

        public async Task<IEnumerable<dynamic>> GetTablesInfoAsync()
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                var query = @"
                    SELECT 
                        t.TABLE_NAME,
                        t.TABLE_TYPE,
                        t.TABLE_SCHEMA,
                        p.rows as RowCounts,
                        CAST(ROUND((SUM(a.total_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS TotalSpaceMB
                    FROM INFORMATION_SCHEMA.TABLES t
                    LEFT JOIN sys.indexes i ON t.TABLE_NAME = OBJECT_NAME(i.object_id)
                    LEFT JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
                    LEFT JOIN sys.allocation_units a ON p.partition_id = a.container_id
                    WHERE t.TABLE_TYPE = 'BASE TABLE'
                    GROUP BY t.TABLE_NAME, t.TABLE_TYPE, t.TABLE_SCHEMA, p.rows
                    ORDER BY t.TABLE_NAME";
                
                var tablesInfo = await connection.QueryAsync(query);
                return tablesInfo;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero informazioni tabelle");
                return Enumerable.Empty<dynamic>();
            }
        }
    }
} 