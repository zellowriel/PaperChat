using Microsoft.AspNetCore.Http.Features;
using PaperChat.API.Extensions;
using PaperChat.API.Middlewares;
using PaperChat.Repositories;
using PaperChat.Service;

var builder = WebApplication.CreateBuilder(args);

const long maxRequestBytes = 51L * 1024 * 1024;
builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = maxRequestBytes);
builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = maxRequestBytes);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddPaperChatRepositories(builder.Configuration);
builder.Services.AddPaperChatServices();
builder.Services.AddPaperChatApi(builder.Configuration, builder.Environment);

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("PaperChatCors");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program { }
