using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ExportController : ControllerBase
    {
        private readonly IExportService _exportService;
        private readonly ILogger<ExportController> _logger;

        public ExportController(IExportService exportService, ILogger<ExportController> logger)
        {
            _exportService = exportService;
            _logger = logger;
        }

        [HttpGet("{tableName}/excel")]
        public async Task<IActionResult> ExportToExcel(string tableName, [FromQuery] int? maxRows = null)
        {
            try
            {
                var excelData = await _exportService.ExportToExcelAsync(tableName, maxRows);
                return File(excelData, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"{tableName}.xlsx");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione Excel tabella: {tableName}");
                return StatusCode(500, "Errore durante esportazione");
            }
        }

        [HttpGet("{tableName}/csv")]
        public async Task<IActionResult> ExportToCsv(string tableName, [FromQuery] int? maxRows = null)
        {
            try
            {
                var csvData = await _exportService.ExportToCsvAsync(tableName, maxRows);
                return File(csvData, "text/csv", $"{tableName}.csv");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione CSV tabella: {tableName}");
                return StatusCode(500, "Errore durante esportazione");
            }
        }

        [HttpGet("{tableName}/json")]
        public async Task<IActionResult> ExportToJson(string tableName, [FromQuery] int? maxRows = null)
        {
            try
            {
                var jsonData = await _exportService.ExportToJsonAsync(tableName, maxRows);
                return File(System.Text.Encoding.UTF8.GetBytes(jsonData), "application/json", $"{tableName}.json");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Errore durante esportazione JSON tabella: {tableName}");
                return StatusCode(500, "Errore durante esportazione");
            }
        }
    }
} 