using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class StoredProceduresController : ControllerBase
    {
        private readonly IStoredProcedureService _storedProcedureService;
        private readonly ILogger<StoredProceduresController> _logger;

        public StoredProceduresController(IStoredProcedureService storedProcedureService, ILogger<StoredProceduresController> logger)
        {
            _storedProcedureService = storedProcedureService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStoredProcedures()
        {
            try
            {
                var procedures = await _storedProcedureService.GetStoredProcedureNamesAsync();
                return Ok(procedures);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero stored procedures");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("{procedureName}/execute")]
        public async Task<IActionResult> ExecuteStoredProcedure(string procedureName, [FromBody] Dictionary<string, object>? parameters = null)
        {
            try
            {
                if (!await _storedProcedureService.StoredProcedureExistsAsync(procedureName))
                {
                    return NotFound($"Stored procedure '{procedureName}' non trovata");
                }

                var result = await _storedProcedureService.ExecuteStoredProcedureAsync(procedureName, parameters);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esecuzione stored procedure: {procedureName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{procedureName}/parameters")]
        public async Task<IActionResult> GetStoredProcedureParameters(string procedureName)
        {
            try
            {
                if (!await _storedProcedureService.StoredProcedureExistsAsync(procedureName))
                {
                    return NotFound($"Stored procedure '{procedureName}' non trovata");
                }

                var parameters = await _storedProcedureService.GetStoredProcedureParametersAsync(procedureName);
                return Ok(parameters);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante recupero parametri stored procedure: {procedureName}");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("execute-query")]
        public async Task<IActionResult> ExecuteCustomQuery([FromBody] CustomQueryRequest request)
        {
            try
            {
                var result = await _storedProcedureService.ExecuteCustomQueryAsync(request.Query, request.Parameters);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante esecuzione query personalizzata");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("database-info")]
        public async Task<IActionResult> GetDatabaseInfo()
        {
            try
            {
                var info = await _storedProcedureService.GetDatabaseInfoAsync();
                return Ok(info);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero informazioni database");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("tables-info")]
        public async Task<IActionResult> GetTablesInfo()
        {
            try
            {
                var tablesInfo = await _storedProcedureService.GetTablesInfoAsync();
                return Ok(tablesInfo);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero informazioni tabelle");
                return StatusCode(500, "Errore interno del server");
            }
        }
    }

} 