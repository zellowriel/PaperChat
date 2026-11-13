using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using PaperChat.Service.Common;

namespace PaperChat.API.Middlewares;

public sealed class ExceptionHandlingMiddleware(
    RequestDelegate next,
    ILogger<ExceptionHandlingMiddleware> logger,
    IHostEnvironment environment)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
        {
            // Client đã ngắt kết nối; không cố ghi response.
        }
        catch (Exception exception)
        {
            if (context.Response.HasStarted) throw;
            await WriteProblemAsync(context, exception);
        }
    }

    private async Task WriteProblemAsync(HttpContext context, Exception exception)
    {
        var statusCode = StatusCodes.Status500InternalServerError;
        var title = "Internal Server Error";
        var detail = "Đã xảy ra lỗi không mong muốn.";

        switch (exception)
        {
            case AppException appException:
                statusCode = appException.StatusCode;
                title = appException.Title;
                detail = appException.Message;
                logger.LogWarning(exception, "Request lỗi nghiệp vụ: {Path}", context.Request.Path);
                break;
            case ValidationException validationException:
                statusCode = StatusCodes.Status400BadRequest;
                title = "Dữ liệu không hợp lệ";
                detail = validationException.Message;
                logger.LogWarning(exception, "Validation error: {Path}", context.Request.Path);
                break;
            case DbUpdateException { InnerException: PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } }:
                statusCode = StatusCodes.Status409Conflict;
                title = "Conflict";
                detail = "Dữ liệu bị trùng với một bản ghi đã tồn tại.";
                logger.LogWarning(exception, "Database unique constraint violation: {Path}", context.Request.Path);
                break;
            default:
                logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
                if (environment.IsDevelopment()) detail = exception.Message;
                break;
        }

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";
        var problem = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };
        problem.Extensions["traceId"] = context.TraceIdentifier;
        await context.Response.WriteAsJsonAsync(problem, cancellationToken: context.RequestAborted);
    }
}
