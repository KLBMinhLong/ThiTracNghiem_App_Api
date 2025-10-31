# 🧾 CHỨC NĂNG ĐĂNG KÝ TÀI KHOẢN - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng

```
RegisterScreen (UI) → AuthProvider.register() → AuthService.register() →
POST /api/Auth/register → AuthController.Register() → UserManager.CreateAsync →
Add role "User" → BuildAuthResponseAsync → trả về JWT + thông tin user →
Flutter lưu token (TokenStorage) → Điều hướng về màn hình đăng nhập
```

## 2. Thành phần tham gia & vị trí mã nguồn

| Bước | Mô tả | File & dòng |
|------|-------|-------------|
| 1 | Render form đăng ký, validate input | `lib/screens/register_screen.dart` (dòng 23-244) |
| 2 | Gọi provider để gửi dữ liệu | `register_screen.dart` hàm `_register` (dòng 230-246) |
| 3 | Provider điều phối trạng thái/loading | `lib/providers/auth_provider.dart` (dòng 162-194) |
| 4 | Tầng service đóng gói API call | `lib/services/auth_service.dart` (dòng 63-96) |
| 5 | Tầng API xử lý request | `ThiTracNghiemApi/Controllers/AuthController.cs` (dòng 33-101) |
| 6 | DTO validate dữ liệu đầu vào | `ThiTracNghiemApi/Dtos/Auth/RegisterRequest.cs` (dòng 6-44) |
| 7 | Sinh JWT & map user → DTO | `AuthController.BuildAuthResponseAsync` (dòng 650-670) + `Extensions/UserMappingExtensions.cs` |
| 8 | Lưu session vào thiết bị | `AuthProvider._persistSession` (dòng 74-121) + `lib/core/token_storage.dart` |

> Ghi chú: Số dòng dựa trên commit hiện tại (31/10/2025). Nếu file thay đổi, hãy tìm theo tên hàm tương ứng.

## 3. Phân tích từng lớp

### 3.1 Giao diện người dùng (Flutter)

- **`RegisterScreen`** tạo form với 5 trường bắt buộc: Tên đăng nhập, Họ tên, Email, Mật khẩu, Xác nhận mật khẩu.
- Mỗi `TextFormField` có validator cụ thể: kiểm tra rỗng, pattern email, mật khẩu >= 6 ký tự và chứa chữ + số, xác nhận mật khẩu trùng khớp.
- Khi nhấn "Đăng ký" (`_register`), nếu form hợp lệ sẽ gọi `AuthProvider.register` và hiển thị loading thông qua `auth.isLoading`.
- Nếu đăng ký thành công: hiển thị snackbar thành công và `Navigator.pop()` quay về màn hình đăng nhập.
- Nếu thất bại: lấy thông điệp thân thiện `_friendlyAuthError` để thông báo cho người dùng.

### 3.2 Provider (Quản lý trạng thái)

- **`AuthProvider.register`**
  - Đặt `_isLoading = true`, reset `_error`.
  - Gọi `AuthService.register` truyền tham số (bao gồm cả tùy chọn fullName).
  - Nếu backend trả về `AuthResponse`, gọi `_persistSession` để lưu token + user vào `TokenStorage` và bộ nhớ.
  - Nếu xảy ra `ApiException`, ghi `_error`, xoá session cục bộ để tránh lệch trạng thái, trả về `false`.
  - Dừng loading và `notifyListeners()`.

- **`_persistSession`** (dòng 74-121 cùng file) viết token, expiry, user vào `TokenStorage` (sử dụng `flutter_secure_storage`).

### 3.3 Service (HTTP client)

- **`AuthService.register`**
  - Chuẩn bị payload JSON, chỉ thêm các field không null.
  - Gọi `_client.post('/api/Auth/register', body: payload)`.
  - Validate response phải là `Map<String, dynamic>` rồi parse thành `AuthResponse`.
  - Ném `ApiException` nếu response sai định dạng.

- **`ApiClient.post`** (xem `lib/core/api_client.dart`, dòng 44-142) chịu trách nhiệm:
  - Gắn `Authorization: Bearer {token}` nếu đã có.
  - Encode JSON, gửi request bằng `http.Client`.
  - Parse response (tự decode JSON, ném lỗi nếu status >= 400).

### 3.4 Backend Controller

- **`AuthController.Register`** (dòng 33-101):
  1. Kiểm tra `ModelState` (thuộc tính `[Required]`, `[EmailAddress]`, `[StringLength]`...).
  2. Chuẩn hoá dữ liệu (`Trim()` username, email, full name).
  3. Kiểm tra trùng tên đăng nhập/email bằng `_userManager.Users.AnyAsync` → trả HTTP 409 và thông báo tiếng Việt nếu trùng.
  4. Tạo `ApplicationUser` mới, map thêm các trường tuỳ chọn (`NgaySinh`, `GioiTinh`, `SoDienThoai`, `AvatarUrl`).
  5. `_userManager.CreateAsync(user, request.Password)` sử dụng ASP.NET Identity để hash mật khẩu và lưu DB.
  6. Nếu lỗi, add từng `IdentityError` vào `ModelState` → trả `ValidationProblem` với danh sách lỗi.
  7. Gán role mặc định `User` thông qua `_userManager.AddToRoleAsync`.
  8. Gọi `BuildAuthResponseAsync(user)` để tạo `AuthResponse` (JWT, hạn token, user info, roles).
  9. Trả `Ok(AuthResponse)` cho front-end.

### 3.5 DTO & Mapping

- **`RegisterRequest`** (dòng 6-44) chứa validation attribute giúp ASP.NET tự động trả lỗi tiếng Việt.
- **`UserMappingExtensions.ToUserDto`** chuyển `ApplicationUser` → `UserResponse` để client sử dụng.
- **`AuthResponse`** (`ThiTracNghiemApi/Dtos/Auth/AuthResponse.cs`) đóng gói token + user + expiresAt cho Flutter.

## 4. Giao tiếp API

- **Endpoint**: `POST /api/Auth/register`
- **Request body JSON** (ví dụ):

```json
{
  "username": "minhnguyen",
  "email": "minh@example.com",
  "password": "Pass1234",
  "confirmPassword": "Pass1234",
  "firstName": "Minh",
  "lastName": "Nguyen",
  "phoneNumber": "0912345678"
}
```

- **Response 200**:

```json
{
  "token": "<JWT>",
  "expiresAt": "2025-11-30T12:15:30Z",
  "user": {
    "id": "...",
    "username": "minhnguyen",
    "email": "minh@example.com",
    "fullName": "Minh Nguyen",
    "roles": ["User"],
    "avatarUrl": null
  }
}
```

- **Các mã lỗi chính**:
  - `400 BadRequest`: ModelState không hợp lệ (thiếu trường, email sai, mật khẩu không khớp).
  - `409 Conflict`: Username hoặc email đã tồn tại.
  - `500 InternalServerError`: Lỗi không mong muốn (Serilog log chi tiết).

## 5. Xử lý lỗi & UX

- Flutter map lỗi thông qua `_friendlyAuthError` trong `AuthProvider` để hiển thị message dễ hiểu.
- Nếu backend trả danh sách lỗi `ValidationProblem`, `ApiClient` ném `ApiException` với `details` giúp hiển thị từng lỗi cụ thể.
- Khi đăng ký thất bại, provider bảo đảm xoá token partial và đưa UI về trạng thái ổn định.

## 6. Kiểm thử đề xuất

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Form validation unit test | `flutter_test` | Đảm bảo validator hoạt động đúng khi nhập thiếu/sai |
| AuthProvider test | `mockito` + fake `AuthService` | Kiểm tra loading state, xử lý thành công/thất bại |
| Integration API test | `xUnit` hoặc `WebApplicationFactory` | Đảm bảo endpoint trả mã lỗi chính xác |
| Manual QA | Postman + thiết bị thật | Kiểm tra thông báo tiếng Việt, token lưu trữ, điều hướng |

## 7. Ghi chú triển khai

- Role default "User" phải tồn tại trong DB (`AspNetRoles`). Nếu seed chưa có, đăng ký sẽ lỗi.
- JWT secret, issuer, audience cấu hình trong `appsettings.json`; Flutter tin vào `expiresAt` để tự refresh.
- Flutter dùng `flutter_secure_storage`, cần kiểm tra quyền Keychain/Keystore trên môi trường thật.
- Khi đổi schema `RegisterRequest`, phải cập nhật đồng bộ UI và `AuthService.register`.
