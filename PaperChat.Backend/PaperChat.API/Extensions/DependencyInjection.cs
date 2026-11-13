using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using PaperChat.API.AI;
using PaperChat.Service.Interfaces;
using Microsoft.Extensions.Options;
using PaperChat.Service.Common;
using PaperChat.Service.Implementations;

namespace PaperChat.API.Extensions;

public static class DependencyInjection
{
    public static IServiceCollection AddPaperChatApi(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        var jwt = configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()
            ?? throw new InvalidOperationException("Thiếu cấu hình Jwt.");

        if (Encoding.UTF8.GetByteCount(jwt.Key) < 32)
            throw new InvalidOperationException("Jwt:Key phải có tối thiểu 32 bytes. Hãy dùng secret riêng qua Environment Variables/Secret Manager.");
        if (jwt.ExpirationMinutes is < 1 or > 1440)
            throw new InvalidOperationException("Jwt:ExpirationMinutes phải từ 1 đến 1440.");

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, HttpCurrentUserService>();
        services.AddScoped<ITokenService, JwtTokenService>();
        services.AddScoped<FirebaseUserProvisioner>();

        var firebaseProjectId = configuration["Firebase:ProjectId"];
        if (string.IsNullOrWhiteSpace(firebaseProjectId))
            throw new InvalidOperationException("Thiếu cấu hình Firebase:ProjectId.");

        var firebaseIssuer = $"https://securetoken.google.com/{firebaseProjectId}";
        services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = "SmartBearer";
                options.DefaultChallengeScheme = "SmartBearer";
            })
            .AddPolicyScheme("SmartBearer", "Firebase or legacy bearer token", options =>
            {
                options.ForwardDefaultSelector = context =>
                {
                    var authorization = context.Request.Headers.Authorization.ToString();
                    if (!authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                        return "LocalJwt";

                    var token = authorization["Bearer ".Length..].Trim();
                    var handler = new JwtSecurityTokenHandler();
                    if (!handler.CanReadToken(token)) return "LocalJwt";
                    try
                    {
                        return handler.ReadJwtToken(token).Issuer == firebaseIssuer
                            ? "Firebase"
                            : "LocalJwt";
                    }
                    catch (ArgumentException)
                    {
                        return "LocalJwt";
                    }
                };
            })
            .AddJwtBearer("LocalJwt", options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwt.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwt.Audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
            })
            .AddJwtBearer("Firebase", options =>
            {
                options.Authority = firebaseIssuer;
                options.Audience = firebaseProjectId;
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = firebaseIssuer,
                    ValidateAudience = true,
                    ValidAudience = firebaseProjectId,
                    ValidateLifetime = true,
                    NameClaimType = "name"
                };
                options.Events = new JwtBearerEvents
                {
                    OnTokenValidated = async context =>
                    {
                        var principal = context.Principal;
                        var uid = principal?.FindFirst("user_id")?.Value
                            ?? principal?.FindFirst("sub")?.Value;
                        var email = principal?.FindFirst("email")?.Value;
                        if (string.IsNullOrWhiteSpace(uid) || string.IsNullOrWhiteSpace(email))
                        {
                            context.Fail("Firebase token must include a user ID and email.");
                            return;
                        }

                        var provisioner = context.HttpContext.RequestServices
                            .GetRequiredService<FirebaseUserProvisioner>();
                        var userId = await provisioner.GetOrCreateAsync(
                            uid,
                            email,
                            principal?.FindFirst("name")?.Value,
                            string.Equals(
                                principal?.FindFirst("email_verified")?.Value,
                                "true",
                                StringComparison.OrdinalIgnoreCase),
                            context.HttpContext.RequestAborted);

                        if (principal?.Identity is ClaimsIdentity identity)
                        {
                            var existingId = identity.FindFirst(ClaimTypes.NameIdentifier);
                            if (existingId is not null) identity.RemoveClaim(existingId);
                            identity.AddClaim(new Claim(ClaimTypes.NameIdentifier, userId.ToString()));
                        }
                    }
                };
            });
        services.AddAuthorization();

        services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc("v1", new OpenApiInfo { Title = "PaperChat API", Version = "v1" });
            options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Name = "Authorization",
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = ParameterLocation.Header,
                Description = "Nhập JWT access token. Ví dụ: Bearer {token}"
            });
            options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
            {
                [new OpenApiSecuritySchemeReference("Bearer", document)] = []
            });
        });

        // ==========================================
        // GEMINI AI CONFIGURATION
        // ==========================================

        services.Configure<GeminiOptions>(
            configuration.GetSection(GeminiOptions.SectionName)
        );

        // Đăng ký HttpClient để gọi Gemini REST API.
        services.AddHttpClient<GeminiAiChatService>(
            (serviceProvider, client) =>
            {
                var geminiOptions = serviceProvider
                    .GetRequiredService<IOptions<GeminiOptions>>()
                    .Value;

                var timeout = Math.Clamp(
                    geminiOptions.TimeoutSeconds,
                    15,
                    600
                );

                client.Timeout = TimeSpan.FromSeconds(timeout);
            }
        );

        // IAiChatService sẽ sử dụng implementation Gemini thật.
        // Không còn sử dụng DevelopmentMockAiChatService.
        services.AddScoped<IAiChatService>(
            serviceProvider =>
                serviceProvider.GetRequiredService<GeminiAiChatService>()
        );

        var allowedOrigins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
        services.AddCors(options => options.AddPolicy("PaperChatCors", policy =>
        {
            if (environment.IsDevelopment())
                policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
            else if (allowedOrigins.Length > 0)
                policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod();
            else
                policy.SetIsOriginAllowed(_ => false);
        }));

        return services;
    }
}
