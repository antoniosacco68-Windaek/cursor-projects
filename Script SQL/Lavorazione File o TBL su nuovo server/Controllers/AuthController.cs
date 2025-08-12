using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Backend.Models;
using Backend.Services;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, IConfiguration configuration, ILogger<AuthController> logger)
        {
            _authService = authService;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                _logger.LogInformation($"Tentativo di login per: {request.Username}");
                
                var user = await _authService.ValidateUserAsync(request.Username, request.Password);
                
                if (user == null)
                {
                    _logger.LogWarning($"Login fallito per: {request.Username} - credenziali non valide");
                    return Unauthorized(new { message = "Username o password non validi" });
                }

                _logger.LogInformation($"Utente validato: {user.Username}, ruolo: {user.Role}");
                
                var token = GenerateJwtToken(user);
                
                _logger.LogInformation($"Token generato per: {user.Username}");
                
                var response = new LoginResponse
                {
                    Token = token,
                    Username = user.Username,
                    Role = user.Role,
                    ExpiresAt = DateTime.UtcNow.AddHours(1)
                };

                _logger.LogInformation($"Login completato con successo per: {user.Username}");
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante login per utente: {Username}", request.Username);
                return StatusCode(500, new { message = "Errore interno del server" });
            }
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
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
                _logger.LogError(ex, "Errore durante registrazione");
                return StatusCode(500, new { message = "Errore interno del server" });
            }
        }

        [HttpGet("validate")]
        [Microsoft.AspNetCore.Authorization.Authorize]
        public IActionResult ValidateToken()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value;
            var role = User.FindFirst(ClaimTypes.Role)?.Value;
            
            return Ok(new { 
                message = "Token valido", 
                username = username, 
                role = role 
            });
        }

        private string GenerateJwtToken(User user)
        {
            try
            {
                var jwtSettings = _configuration.GetSection("JWT");
                var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? "SuperSecretKey123!@#$%^&*()");

                var tokenHandler = new JwtSecurityTokenHandler();
                var tokenDescriptor = new SecurityTokenDescriptor
                {
                    Subject = new ClaimsIdentity(new[]
                    {
                        new Claim(ClaimTypes.Name, user.Username),
                        new Claim(ClaimTypes.Role, user.Role),
                        new Claim(ClaimTypes.NameIdentifier, user.Id > 0 ? user.Id.ToString() : user.Username)
                    }),
                    Expires = DateTime.UtcNow.AddHours(1),
                    Issuer = jwtSettings["Issuer"] ?? "SQLTableManager",
                    Audience = jwtSettings["Audience"] ?? "SQLTableManager-API",
                    SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
                };

                var token = tokenHandler.CreateToken(tokenDescriptor);
                return tokenHandler.WriteToken(token);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Errore durante generazione token JWT per utente: {Username}", user.Username);
                throw;
            }
        }
    }

    public class RegisterRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Role { get; set; } = "User";
    }
} 