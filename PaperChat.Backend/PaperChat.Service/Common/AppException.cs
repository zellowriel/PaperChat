namespace PaperChat.Service.Common;

public class AppException(int statusCode, string title, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
    public string Title { get; } = title;
}

public sealed class ValidationAppException(string message)
    : AppException(400, "Dữ liệu không hợp lệ", message);

public sealed class UnauthorizedAppException(string message = "Thông tin đăng nhập không hợp lệ.")
    : AppException(401, "Unauthorized", message);

public sealed class ForbiddenAppException(string message = "Bạn không có quyền thực hiện thao tác này.")
    : AppException(403, "Forbidden", message);

public sealed class NotFoundException(string message = "Không tìm thấy tài nguyên.")
    : AppException(404, "Not Found", message);

public sealed class ConflictException(string message)
    : AppException(409, "Conflict", message);

public sealed class PayloadTooLargeException(string message)
    : AppException(413, "Payload Too Large", message);

public sealed class ServiceUnavailableException(string message)
    : AppException(503, "Service Unavailable", message);
