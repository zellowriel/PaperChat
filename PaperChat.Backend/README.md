# PaperChat Backend API

Source backend theo cấu trúc 3 project `PaperChat.API`, `PaperChat.Service`, `PaperChat.Repositories`, áp dụng REST API, Firebase ID token/JWT, EF Core và PostgreSQL.

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

## 3. Tạo schema database

Với Neon, mở SQL Editor của database đã chọn (thường là `neondb`) và chạy
`database/02_create_tables.sql`, sau đó chạy
`database/03_add_firebase_uid.sql`. Hai script tạo các bảng nền và cột Firebase
UID; chạy chúng trước khi triển khai API mới.

`02_create_tables.sql` dùng `IF NOT EXISTS` để không tạo lại bảng/index đã có.
Nếu database đã chứa dữ liệu, hãy kiểm tra tên bảng/cột lowercase và kiểu dữ
liệu khớp với `AppDbContext`; không chạy lại các script trên schema khác biệt
mà chưa sao lưu. Với PostgreSQL tự quản lý, tạo database trước bằng công cụ của
nhà cung cấp rồi chạy các script trong đúng database đó.

## 4. Cấu hình

Chỉnh `PaperChat.API/appsettings.json` cho local development, hoặc ưu tiên dùng Environment Variables / Secret Manager cho môi trường thật:

```bash
ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=paperchat_db;Username=postgres;Password=YOUR_DB_PASSWORD"
Jwt__Key="REPLACE_WITH_A_RANDOM_SECRET_AT_LEAST_32_BYTES"
Firebase__ProjectId="YOUR_FIREBASE_PROJECT_ID"
Gemini__ApiKey="YOUR_GEMINI_API_KEY"
Storage__RootPath="App_Data/files"
```

Không commit database password hoặc JWT signing key thật lên Git. Mẫu `Jwt:Key` trong appsettings chỉ là key development; phải thay bằng secret riêng.
`Gemini:ApiKey` cũng chỉ cấu hình qua biến môi trường hoặc secret manager.
`Firebase:ProjectId` phải khớp với project phát hành Firebase ID token. Backend
chấp nhận Firebase ID token và JWT cũ trong giai đoạn chuyển đổi.

Với Docker Compose, tạo file `.env` cục bộ trong thư mục `PaperChat.Backend`
(file này đã được Git ignore) và đặt `FIREBASE_PROJECT_ID`,
`NEON_CONNECTION_STRING`, cùng `GEMINI_API_KEY`; sau đó chạy
`docker compose up --build`. Không đưa các giá trị bí mật vào file compose.

Lần đầu Firebase UID gọi API, backend tự tạo hoặc liên kết hồ sơ SQL theo email.
Để liên kết an toàn với tài khoản SQL cũ, email Firebase phải được xác minh;
thư viện PDF, tiến độ đọc và lịch sử chat hiện có vẫn được giữ nguyên.

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
| POST | `/api/v1/auth/register` | No | Legacy: tạo tài khoản SQL, trả JWT |
| POST | `/api/v1/auth/login` | No | Legacy: đăng nhập SQL, trả JWT |
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

Flutter hiện dùng Firebase Authentication; hai endpoint đăng ký/đăng nhập SQL
là legacy. Với endpoint được bảo vệ, gửi Firebase ID token hoặc JWT legacy:

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

## 7. Giới hạn hiện tại

- **PDF + AI:** `PdfProcessingService` trích xuất text và số trang bằng PdfPig.
  PDF scan cần OCR, hiện chưa hỗ trợ. Chat gửi toàn bộ text của tài liệu cho
  Gemini; chưa có embeddings/vector search nên đây chưa phải RAG đầy đủ. Nội
  dung vượt quá `Gemini:MaxDocumentCharacters` bị từ chối.
- **Gemini:** API thật được đăng ký qua `GeminiAiChatService`; cần cấu hình
  `Gemini:ApiKey` hợp lệ để chat hoạt động. `DevelopmentMockAiChatService` còn
  trong source nhưng không được đăng ký làm implementation hiện tại.
- **Storage:** `LocalFileStorage` lưu file và text trên máy host. Docker Compose
  bind-mount `App_Data`, phù hợp demo một máy; khi deploy nhiều instance cần
  object storage như S3/MinIO/Azure Blob.
- **Quota Plan PRO:** đề bài chỉ nêu mức 10 GB và `FREE/PRO`, chưa định nghĩa quota riêng cho PRO; hiện scaffold áp dụng 10 GB cho mọi plan.
- **Download:** File được giữ private trong `Storage:RootPath`, không public static. Client gọi endpoint `/file` có authorize.

## 8. Một vài lưu ý production

- Bật HTTPS, quản lý JWT/database secrets bằng Secret Manager hoặc biến môi trường.
- Thêm rate limiting cho login/chat/upload, virus scanning cho file upload, cleanup job cho file mồ côi và kiểm thử integration.
- Không log password, JWT hoặc nội dung PDF/chat nhạy cảm.
- Nếu chạy nhiều instance API, dùng object storage dùng chung thay cho local disk.
