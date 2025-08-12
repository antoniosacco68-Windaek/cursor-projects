using Backend.Models;

namespace Backend.Services
{
    public interface IAuthService
    {
        Task<User?> ValidateUserAsync(string username, string password);
        Task<User?> GetUserByUsernameAsync(string username);
        Task<User?> CreateUserAsync(string username, string password, string role = "User");
        Task<bool> ChangePasswordAsync(string username, string oldPassword, string newPassword);
        Task<List<User>> GetAllUsersAsync();
        Task<bool> DeleteUserAsync(string username);
    }
} 