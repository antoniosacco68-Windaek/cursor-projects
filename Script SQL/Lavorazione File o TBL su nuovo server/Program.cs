using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Backend.Data;
using Backend.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null; // Mantiene PascalCase
    });
builder.Services.AddEndpointsApiExplorer();

// Swagger con supporto JWT
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "SQL Table Manager API", 
        Version = "v1",
        Description = "API sicura per gestione tabelle SQL Server"
    });
    
    // Configurazione JWT per Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header usando Bearer scheme. Esempio: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header,
            },
            new List<string>()
        }
    });
});

// JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JWT");
        var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? "SuperSecretKey123!@#$%^&*()SuperSecretKey123!@#$%^&*()SuperSecretKey123!@#$%^&*()SuperSecretKey123!@#$%^&*()");

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false; // Solo per sviluppo
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = jwtSettings["Issuer"] ?? "SQLTableManager",
        ValidAudience = jwtSettings["Audience"] ?? "SQLTableManager-API",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// Database connection
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Custom services
builder.Services.AddScoped<ITableService, TableService>();
builder.Services.AddScoped<IExportService, ExportService>();
builder.Services.AddScoped<IStoredProcedureService, StoredProcedureService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// CORS configuration for frontend
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "https://localhost:3001") // Development
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
    
    options.AddPolicy("Production", policy =>
    {
        policy.WithOrigins("https://yourdomain.com") // Sostituisci con il tuo dominio
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Configure URLs
builder.WebHost.UseUrls("http://localhost:8001", "https://localhost:8002");

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors("AllowReactApp");
}
else
{
    app.UseCors("Production");
    app.UseHttpsRedirection();
}

// Serve static files (React build)
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Fallback to index.html for SPA routing
app.MapFallbackToFile("index.html");

app.Run(); 