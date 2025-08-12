using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class TablesController : ControllerBase
    {
        private readonly ITableService _tableService;
        private readonly ILogger<TablesController> _logger;

        public TablesController(ITableService tableService, ILogger<TablesController> logger)
        {
            _tableService = tableService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetTables()
        {
            try
            {
                var tables = await _tableService.GetTableNamesAsync();
                return Ok(tables);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero tabelle");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{tableName}")]
        public async Task<IActionResult> GetTableData(string tableName, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var data = await _tableService.GetTableDataAsync(tableName, page, pageSize);
                var totalRows = await _tableService.GetTableRowCountAsync(tableName);

                return Ok(new
                {
                    Data = data,
                    TotalRows = totalRows,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = (int)Math.Ceiling((double)totalRows / pageSize)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero dati tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{tableName}/schema")]
        public async Task<IActionResult> GetTableSchema(string tableName)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var schema = await _tableService.GetTableSchemaAsync(tableName);
                return Ok(schema);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero schema tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("{tableName}/insert")]
        public async Task<IActionResult> InsertRecord(string tableName, [FromBody] Dictionary<string, object> record)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var result = await _tableService.InsertRecordAsync(tableName, record);
                return Ok(new { message = "Record inserito con successo", affectedRows = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante inserimento record in tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPut("{tableName}/update")]
        public async Task<IActionResult> UpdateRecord(string tableName, [FromBody] UpdateRecordRequest request)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var result = await _tableService.UpdateRecordAsync(tableName, request.WhereClause, request.NewValues);
                return Ok(new { message = "Record aggiornato con successo", affectedRows = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante aggiornamento record in tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpDelete("{tableName}/delete")]
        public async Task<IActionResult> DeleteRecord(string tableName, [FromBody] Dictionary<string, object> whereClause)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var result = await _tableService.DeleteRecordAsync(tableName, whereClause);
                return Ok(new { message = "Record eliminato con successo", affectedRows = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante eliminazione record in tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("{tableName}/query")]
        public async Task<IActionResult> ExecuteCustomQuery(string tableName, [FromBody] CustomQueryRequest request)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var result = await _tableService.ExecuteCustomQueryAsync(tableName, request.Query, request.Parameters);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esecuzione query personalizzata in tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{tableName}/count")]
        public async Task<IActionResult> GetTableRowCount(string tableName)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var count = await _tableService.GetTableRowCountAsync(tableName);
                return Ok(new { tableName, rowCount = count });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante conteggio righe tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{tableName}/primary-key")]
        public async Task<IActionResult> GetPrimaryKeyColumn(string tableName)
        {
            try
            {
                if (!await _tableService.TableExistsAsync(tableName))
                {
                    return NotFound($"Tabella '{tableName}' non trovata");
                }

                var primaryKey = await _tableService.GetPrimaryKeyColumnAsync(tableName);
                return Ok(new { tableName, primaryKeyColumn = primaryKey });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero chiave primaria tabella: {tableName}");
                return StatusCode(500, "Errore interno del server");
            }
        }
    }

    public class UpdateRecordRequest
    {
        public Dictionary<string, object> WhereClause { get; set; } = new();
        public Dictionary<string, object> NewValues { get; set; } = new();
    }

    public class CustomQueryRequest
    {
        public string Query { get; set; } = string.Empty;
        public Dictionary<string, object>? Parameters { get; set; }
    }
} 