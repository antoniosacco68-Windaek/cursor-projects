using BCrypt.Net;
using Backend.Services;
using Backend.Models;
using System.Text.Json;

namespace Backend.Services;

public class AuthService : IAuthService
{
    private readonly string _usersFile;
    private readonly ILogger<AuthService> _logger;

    public AuthService(ILogger<AuthService> logger)
    {
        _logger = logger;
        _usersFile = Path.Combine(Directory.GetCurrentDirectory(), "Data", "users.json");
        
        // Assicurati che la directory Data esista
        var dataDir = Path.GetDirectoryName(_usersFile);
        if (!Directory.Exists(dataDir))
        {
            Directory.CreateDirectory(dataDir!);
        }
        
        _logger.LogInformation($"File utenti configurato: {_usersFile}");
        
        // Inizializza con utente admin se non esiste
        _ = InitializeDefaultAdminAsync();
    }

    public async Task<User?> ValidateUserAsync(string username, string password)
    {
        try
        {
            _logger.LogInformation($"Tentativo di login per utente: {username}");
            
            var users = await LoadUsersAsync();
            var user = users.FirstOrDefault(u => 
                u.Username.Equals(username, StringComparison.OrdinalIgnoreCase) && 
                u.IsActive);

            if (user == null)
            {
                _logger.LogWarning($"Utente non trovato o inattivo: {username}");
                return null;
            }

            // Verifica password
            bool isValidPassword = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
            
            if (!isValidPassword)
            {
                _logger.LogWarning($"Password non valida per utente: {username}");
                return null;
            }

            // Login riuscito
            await SaveUsersAsync(users);
            
            _logger.LogInformation($"Login riuscito per utente: {username}");
            return user;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Errore durante validazione utente: {username}");
            return null;
        }
    }

    public async Task<User?> GetUserByUsernameAsync(string username)
    {
        try
        {
            var users = await LoadUsersAsync();
            return users.FirstOrDefault(u => 
                u.Username.Equals(username, StringComparison.OrdinalIgnoreCase) && 
                u.IsActive);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Errore durante ricerca utente: {username}");
            return null;
        }
    }

    public async Task<User?> CreateUserAsync(string username, string password, string role = "User")
    {
        try
        {
            var users = await LoadUsersAsync();
            
            // Controlla se l'utente esiste già
            if (users.Any(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase)))
            {
                _logger.LogWarning($"Tentativo di creare utente già esistente: {username}");
                return null;
            }

            var permissions = GetRolePermissions(role);
            var newUser = new User
            {
                Username = username,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                Role = role,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            users.Add(newUser);
            await SaveUsersAsync(users);
            
            _logger.LogInformation($"Utente creato con successo: {username} (ruolo: {role})");
            return newUser;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Errore durante creazione utente: {username}");
            return null;
        }
    }

    public async Task<bool> ChangePasswordAsync(string username, string oldPassword, string newPassword)
    {
        try
        {
            var users = await LoadUsersAsync();
            var user = users.FirstOrDefault(u => 
                u.Username.Equals(username, StringComparison.OrdinalIgnoreCase) && 
                u.IsActive);

            if (user == null)
            {
                return false;
            }

            // Verifica password attuale
            if (!BCrypt.Net.BCrypt.Verify(oldPassword, user.PasswordHash))
            {
                return false;
            }

            // Aggiorna password
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            await SaveUsersAsync(users);
            
            _logger.LogInformation($"Password cambiata per utente: {username}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Errore durante cambio password per utente: {username}");
            return false;
        }
    }

    public async Task<List<User>> GetAllUsersAsync()
    {
        try
        {
            return await LoadUsersAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Errore durante caricamento lista utenti");
            return new List<User>();
        }
    }

    public async Task<bool> DeleteUserAsync(string username)
    {
        try
        {
            var users = await LoadUsersAsync();
            var user = users.FirstOrDefault(u => 
                u.Username.Equals(username, StringComparison.OrdinalIgnoreCase));

            if (user == null || user.Username.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                return false; // Non eliminare l'admin
            }

            users.Remove(user);
            await SaveUsersAsync(users);
            
            _logger.LogInformation($"Utente eliminato: {username}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Errore durante eliminazione utente: {username}");
            return false;
        }
    }

    private async Task<List<User>> LoadUsersAsync()
    {
        try
        {
            if (!File.Exists(_usersFile))
            {
                return new List<User>();
            }

            var json = await File.ReadAllTextAsync(_usersFile);
            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = null, // Mantiene PascalCase invece di camelCase
                DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
            };
            
            // Prova prima con il nuovo formato
            try
            {
                var users = JsonSerializer.Deserialize<List<User>>(json, options) ?? new List<User>();
                return users;
            }
            catch
            {
                // Se fallisce, prova con il formato SQLTableManager
                try
                {
                    var sqlTableManagerUsers = JsonSerializer.Deserialize<List<SQLTableManagerUser>>(json, options) ?? new List<SQLTableManagerUser>();
                    return sqlTableManagerUsers.Select(u => new User
                    {
                        Id = 0, // Non presente nel formato SQLTableManager
                        Username = u.Username,
                        PasswordHash = u.PasswordHash,
                        Email = "", // Non presente nel formato SQLTableManager
                        Role = u.Role,
                        CreatedAt = u.CreatedAt,
                        IsActive = u.IsActive
                    }).ToList();
                }
                catch
                {
                    // Se fallisce anche questo, prova con il formato legacy
                    var legacyUsers = JsonSerializer.Deserialize<List<LegacyUser>>(json, options) ?? new List<LegacyUser>();
                    return legacyUsers.Select(u => new User
                    {
                        Id = u.Id,
                        Username = u.Username,
                        PasswordHash = u.PasswordHash,
                        Email = u.Email ?? "",
                        Role = u.Role,
                        CreatedAt = u.CreatedAt,
                        IsActive = u.IsActive
                    }).ToList();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Errore durante caricamento file utenti");
            return new List<User>();
        }
    }

    private async Task SaveUsersAsync(List<User> users)
    {
        try
        {
            var options = new JsonSerializerOptions
            {
                WriteIndented = true,
                PropertyNamingPolicy = null // Mantiene PascalCase invece di camelCase
            };
            var json = JsonSerializer.Serialize(users, options);
            await File.WriteAllTextAsync(_usersFile, json);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Errore durante salvataggio file utenti");
            throw;
        }
    }

    private async Task InitializeDefaultAdminAsync()
    {
        try
        {
            var users = await LoadUsersAsync();
            
            if (!users.Any(u => u.Username.Equals("admin", StringComparison.OrdinalIgnoreCase)))
            {
                await CreateUserAsync("admin", "admin123", "Admin");
                _logger.LogInformation("*** UTENTE ADMIN CREATO ***");
                _logger.LogInformation("Username: admin");
                _logger.LogInformation("Password: admin123");
                _logger.LogInformation("*** CAMBIARE LA PASSWORD IMMEDIATAMENTE! ***");
            }
            else
            {
                _logger.LogInformation("Utente admin già esistente");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Errore durante inizializzazione utente admin");
        }
    }

    private static List<string> GetRolePermissions(string role)
    {
        return role.ToLower() switch
        {
            "admin" => new List<string> { "read", "write", "delete", "export", "manage_users", "execute_procedures" },
            "user" => new List<string> { "read", "write", "export", "execute_procedures" },
            "readonly" => new List<string> { "read", "export" },
            _ => new List<string> { "read" }
        };
    }
}

// Classe per compatibilità con il formato legacy
public class LegacyUser
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Role { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsActive { get; set; } = true;
}

// Classe per compatibilità con il formato SQLTableManager
public class SQLTableManagerUser
{
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public List<string> Permissions { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLogin { get; set; }
    public bool IsActive { get; set; } = true;
} 