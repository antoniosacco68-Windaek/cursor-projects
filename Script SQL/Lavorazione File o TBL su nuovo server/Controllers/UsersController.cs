using Microsoft.AspNetCore.Mvc;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<UsersController> _logger;

        public UsersController(IAuthService authService, ILogger<UsersController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            try
            {
                var users = await _authService.GetAllUsersAsync();
                var userList = users.Select(u => new
                {
                    u.Username,
                    u.Role,
                    u.CreatedAt,
                    u.IsActive
                });
                return Ok(userList);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero lista utenti");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterUser([FromBody] RegisterRequest request)
        {
            try
            {
                var user = await _authService.CreateUserAsync(request.Username, request.Password, request.Role);
                
                if (user == null)
                {
                    return BadRequest(new { message = "Impossibile creare l'utente. Username già esistente." });
                }

                return Ok(new { message = "Utente creato con successo", username = user.Username });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante registrazione utente");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpDelete("{username}")]
        public async Task<IActionResult> DeleteUser(string username)
        {
            try
            {
                var success = await _authService.DeleteUserAsync(username);
                
                if (!success)
                {
                    return BadRequest(new { message = "Impossibile eliminare l'utente. Utente non trovato o admin." });
                }

                return Ok(new { message = "Utente eliminato con successo" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante eliminazione utente");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                var success = await _authService.ChangePasswordAsync(request.Username, request.OldPassword, request.NewPassword);
                
                if (!success)
                {
                    return BadRequest(new { message = "Impossibile cambiare password. Credenziali non valide." });
                }

                return Ok(new { message = "Password cambiata con successo" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante cambio password");
                return StatusCode(500, "Errore interno del server");
            }
        }

        [HttpGet("{username}")]
        public async Task<IActionResult> GetUserProfile(string username)
        {
            try
            {
                var user = await _authService.GetUserByUsernameAsync(username);
                
                if (user == null)
                {
                    return NotFound(new { message = "Utente non trovato" });
                }

                var profile = new
                {
                    user.Username,
                    user.Role,
                    user.CreatedAt,
                    user.IsActive
                };

                return Ok(profile);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante recupero profilo utente");
                return StatusCode(500, "Errore interno del server");
            }
        }
    }

    public class ChangePasswordRequest
    {
        public string Username { get; set; } = string.Empty;
        public string OldPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
} 