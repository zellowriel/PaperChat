# PaperChat Backend API

Source backend theo cấu trúc 3 project `PaperChat.API`, `PaperChat.Service`, `PaperChat.Repositories`, áp dụng REST API, JWT, EF Core và PostgreSQL.

## 1. Yêu cầu

- .NET 10 SDK (LTS).
- PostgreSQL 14+ (khuyến nghị bản còn được hỗ trợ).
- Visual Studio 2026 hoặc VS Code + C# Dev Kit.

## 2. Kiến trúc và chiều phụ thuộc

```text
PaperChat.API  --->  PaperChat.Service  <---  PaperChat.Repositories
       |                                          |
       +--------------- composition root --------+
```

- `Service.Interfaces` chứa các abstraction/port mà nghiệp vụ cần (`IUserRepository`, `IDocumentRepository`, `IFileStorage`, ...).
- `Repositories` implement các port đó. `Repositories.Interfaces.IRepository<T>` chỉ là abstraction nội bộ của persistence; Service không tham chiếu project Repositories.
- API là composition root, chịu trách nhiệm đăng ký DI, JWT, HTTP context và middleware.
- `AppDbContext` map rõ tên bảng/cột lowercase vì script PostgreSQL tạo identifier không đặt trong dấu quote. Điều này giúp EF Core khớp với database đã tạo bằng SQL.

## 3. Tạo database

Chạy `database/01_create_database.sql` riêng bằng tài khoản có quyền tạo database. Sau đó kết nối vào `paperchat_db` rồi chạy `database/02_create_tables.sql`.

Nếu bạn đã tạo DB/bảng bằng SQL ở câu hỏi, không cần chạy lại; chỉ cần kiểm tra tên cột là lowercase như PostgreSQL mặc định.

## 4. Cấu hình

Chỉnh `PaperChat.API/appsettings.json` cho local development, hoặc ưu tiên dùng Environment Variables / Secret Manager cho môi trường thật:

```bash
ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=paperchat_db;Username=postgres;Password=YOUR_DB_PASSWORD"
Jwt__Key="REPLACE_WITH_A_RANDOM_SECRET_AT_LEAST_32_BYTES"
Storage__RootPath="App_Data/files"
```

Không commit database password hoặc JWT signing key thật lên Git. Mẫu `Jwt:Key` trong appsettings chỉ là key development; phải thay bằng secret riêng.

## 5. Chạy API

Từ thư mục chứa `PaperChat.sln`:

```bash
dotnet restore
dotnet build PaperChat.sln
dotnet run --project PaperChat.API
```

Swagger chạy trong Development tại `/swagger`. Khi chạy production, cấu hình danh sách `Cors:AllowedOrigins` phù hợp. Flutter mobile app không chịu CORS; Flutter Web cần khai báo đúng origin.

## 6. Endpoint

| Method | Endpoint | Auth | Mô tả |
|---|---|---:|---|
| POST | `/api/v1/auth/register` | No | Tạo tài khoản, trả JWT |
| POST | `/api/v1/auth/login` | No | Đăng nhập, trả JWT |
| GET | `/api/v1/users/me` | Yes | Hồ sơ và dung lượng hiện tại |
| GET | `/api/v1/documents?page=1&pageSize=20` | Yes | Danh sách tài liệu của user |
| POST | `/api/v1/documents` | Yes | Upload PDF bằng multipart/form-data |
| GET | `/api/v1/documents/{id}` | Yes | Chi tiết tài liệu |
| DELETE | `/api/v1/documents/{id}` | Yes | Xóa tài liệu, chat liên quan và giải phóng quota |
| POST | `/api/v1/chat` | Yes | Hỏi AI theo tài liệu/đoạn trích |
| GET | `/api/v1/chat/{documentId}` | Yes | Lịch sử chat của tài liệu |

Hai endpoint mở rộng hữu ích cho màn hình đọc PDF của Flutter:

- `GET /api/v1/documents/{id}/file`: tải/đọc PDF an toàn qua API thay vì expose đường dẫn filesystem.
- `PATCH /api/v1/documents/{id}/progress`: cập nhật `readingProgress` (0–100).

Với endpoint cần JWT, gửi header:

```http
Authorization: Bearer <access_token>
```

### Register/Login body

```json
{
  "email": "student@example.com",
  "password": "YourPassword123",
  "fullName": "PaperChat Student"
}
```

### Upload PDF

`multipart/form-data` với fields `File` (bắt buộc), `Title` và `Authors` (tùy chọn). API kiểm tra phần mở đầu `%PDF-`, giới hạn file 50 MB và quota lưu trữ 10 GB/user.

### Chat body

```json
{
  "documentId": "00000000-0000-0000-0000-000000000000",
  "question": "Giải thích công thức Scaled Dot-Product?",
  "quote": "We compute the dot products of the query...",
  "chatHistory": []
}
```

Nếu `chatHistory` rỗng, backend dùng lịch sử chat đã lưu trong DB làm context. User chỉ đọc được tài liệu và lịch sử của chính mình.

## 7. Phần cần tích hợp tiếp

- **AI/RAG:** `IAiChatService` là port. Development dùng `DevelopmentMockAiChatService` để kiểm tra luồng API; production trả `503` cho đến khi bạn cài adapter OpenAI/Gemini thật. Adapter thật cần tìm kiếm vector theo `documentId`, tổng hợp câu trả lời và trả `CitationPage` có căn cứ. Chưa có PDF text extraction/embedding trong scaffold này.
- **PDF metadata:** `PageCount` khởi tạo `0`; cần thêm PDF parser/processing worker để đếm trang và trích xuất text.
- **Storage:** `LocalFileStorage` là adapter local. Khi deploy, thay bằng S3/MinIO/Azure Blob nhưng giữ nguyên `IFileStorage`.
- **Quota Plan PRO:** đề bài chỉ nêu mức 10 GB và `FREE/PRO`, chưa định nghĩa quota riêng cho PRO; hiện scaffold áp dụng 10 GB cho mọi plan.
- **Download:** File được giữ private trong `Storage:RootPath`, không public static. Client gọi endpoint `/file` có authorize.

## 8. Một vài lưu ý production

- Bật HTTPS, quản lý JWT/database secrets bằng Secret Manager hoặc biến môi trường.
- Thêm rate limiting cho login/chat/upload, virus scanning cho file upload, cleanup job cho file mồ côi và kiểm thử integration.
- Không log password, JWT hoặc nội dung PDF/chat nhạy cảm.
- Nếu chạy nhiều instance API, dùng object storage dùng chung thay cho local disk.
