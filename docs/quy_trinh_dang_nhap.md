# 🔐 CHỨC NĂNG ĐĂNG NHẬP - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng chính

```
Đăng nhập thường:
LoginScreen → AuthProvider.login() → AuthService.loginRaw() →
POST /api/Auth/login → AuthController.Login() →
  • Nếu requiresTwoFactor = true → trả userId → AuthProvider.pendingTwoFaUserId
  • Nếu thành công → BuildAuthResponseAsync → trả JWT + user → AuthProvider._persistSession → điều hướng Home

Đăng nhập 2FA:
TwoFaLoginScreen → AuthProvider.completeLoginWith2Fa() → AuthService.loginWith2Fa() →
POST /api/Auth/login-2fa → AuthController.LoginWith2Fa() → BuildAuthResponseAsync → Persist session → Home

Đăng nhập Google:
LoginScreen → AuthProvider.loginWithGoogle() → AuthService.loginWithGoogle() →
POST /api/Auth/login/google → AuthController.LoginWithGoogle() →
  • Xác thực Google ID token → Tạo/ cập nhật user → BuildAuthResponseAsync → Persist session → Home
```

## 2. Thành phần & vị trí mã nguồn

| Bước | Mô tả | File & dòng |
|------|-------|-------------|
| 1 | Form đăng nhập, bắt sự kiện nút | `lib/screens/login_screen.dart` (dòng 24-279) |
| 2 | Xử lý submit, map lỗi thân thiện | `login_screen.dart` hàm `_login` & `_friendlyAuthError` (dòng 34-56, 312-350) |
| 3 | Provider điều phối đăng nhập thường | `lib/providers/auth_provider.dart` (`login`, dòng 86-140) |
| 4 | Provider lưu tình trạng 2FA | `auth_provider.dart` (`_pending2FaUserId`, dòng 146-183) |
| 5 | Provider đăng nhập Google | `auth_provider.dart` (`loginWithGoogle`, dòng 189-214) |
| 6 | Provider hoàn tất 2FA | `auth_provider.dart` (`completeLoginWith2Fa`, dòng 150-183) |
| 7 | Service gọi API đăng nhập | `lib/services/auth_service.dart` (`loginRaw`, dòng 25-44) |
| 8 | Service gọi API 2FA | `auth_service.dart` (`loginWith2Fa`, dòng 46-62) |
| 9 | Service đăng nhập Google | `auth_service.dart` (`loginWithGoogle`, dòng 130-146) |
| 10 | Endpoint đăng nhập thường | `ThiTracNghiemApi/Controllers/AuthController.cs` (dòng 208-271, 335-366) |
| 11 | Endpoint đăng nhập Google | `AuthController.cs` (dòng 208-333) |
| 12 | Endpoint xác thực 2FA | `AuthController.cs` (dòng 368-409) |
| 13 | DTO request | `Dtos/Auth/LoginRequest.cs`, `Dtos/Auth/GoogleLoginRequest.cs`, `Dtos/Auth/TwoFaDtos.cs` |
| 14 | Sinh JWT & map user | `AuthController.BuildAuthResponseAsync` (dòng 618-676) + `Extensions/UserMappingExtensions.cs` |
| 15 | Lưu token vào thiết bị | `auth_provider.dart` (`_persistSession`, dòng 48-84) + `lib/core/token_storage.dart` |

> Số dòng tham chiếu theo commit ngày 31/10/2025. Khi file đổi, hãy tìm theo tên hàm tương ứng.

## 3. Giao diện người dùng (Flutter)

- `LoginScreen` tạo form với hai trường: *Tên đăng nhập hoặc email* và *Mật khẩu* kèm validator bắt buộc.
- `_friendlyAuthError` chuyển đổi thông báo hệ thống sang tiếng Việt thân thiện (khóa tài khoản, sai mật khẩu, lỗi mạng).
- Khi người dùng nhấn "Đăng nhập", `_login` kiểm tra hợp lệ, gọi `AuthProvider.login` và hiển thị tiến trình `auth.isLoading`.
- Nếu response yêu cầu 2FA (`auth.pendingTwoFaUserId` khác null), UI điều hướng sang `/login-2fa`.
- Xử lý Google Sign-In qua `_loginWithGoogle`, bao gồm kiểm tra cấu hình `GOOGLE_CLIENT_ID`, sign-out session cũ, nhận `idToken`, gọi provider.

## 4. Provider (AuthProvider)

- **`login`**
  - Bật loading, reset lỗi.
  - Gọi `AuthService.loginRaw` để đọc phản hồi gốc.
  - Nếu backend trả `requiresTwoFactor = true`, lưu `_pending2FaUserId`, tắt loading, `notifyListeners()` để UI chuyển sang màn hình 2FA.
  - Nếu không cần 2FA, parse `AuthResponse`, gọi `_persistSession`, cập nhật `_currentUser`, trả `true`.
  - Bắt `ApiException` và ngoại lệ chung, lưu `_error`, gọi `_clearSession` để tránh trạng thái sai.

- **`completeLoginWith2Fa`**
  - Đọc `pendingTwoFaUserId`; nếu null trả lỗi.
  - Gọi `AuthService.loginWith2Fa`, persist session, reset `_pending2FaUserId`.

- **`loginWithGoogle`**
  - Gọi `AuthService.loginWithGoogle`, persist session, cập nhật `_currentUser`.

- Tất cả đường dẫn đăng nhập đều sử dụng `_persistSession` để lưu token, thời gian hết hạn và user vào `TokenStorage` (Flutter Secure Storage) và đồng bộ `ApiClient` với header `Authorization`.

## 5. Service (AuthService)

- **`loginRaw`** gửi `POST /api/Auth/login` với payload `{'userName': identifier, 'password': password}`.
  - Trả về `Map<String, dynamic>` để provider tự quyết định parse hay không.
  - Nếu response không phải JSON map → ném `ApiException` với thông điệp tiếng Việt.

- **`loginWith2Fa`** gửi `POST /api/Auth/login-2fa` với `{ 'userId': userId, 'code': code }`, parse `AuthResponse`.

- **`loginWithGoogle`** gửi `POST /api/Auth/login/google` với `{ 'idToken': idToken }`, parse `AuthResponse`.

- Các phương thức sử dụng `ApiClient` để tự gắn header, encode JSON, xử lý lỗi HTTP >= 400 thành `ApiException`.

## 6. Backend Controller

### 6.1 `/api/Auth/login`

1. Validate `ModelState` dựa trên `LoginRequest` `[Required]` + `[StringLength]`.
2. Cho phép đăng nhập bằng username hoặc email (`identifier.Contains("@")`).
3. Kiểm tra tồn tại user; trả `401 Unauthorized` nếu không có.
4. Kiểm tra trạng thái khóa `TrangThaiKhoa` hoặc lockout; trả `403 Forbid` với thông điệp tiếng Việt.
5. Kiểm tra mật khẩu bằng `CheckPasswordAsync`.
6. Nếu `TwoFactorEnabled == true`, trả `200 OK` với `{ requiresTwoFactor: true, userId }`.
7. Nếu không, `SignInManager.SignInAsync` và trả `AuthResponse` chứa JWT, hạn token, thông tin người dùng, roles.

### 6.2 `/api/Auth/login-2fa`

1. Validate `TwoFaLoginRequest`.
2. Tìm user theo `UserId`. Nếu không thấy → `401`.
3. Verify code thông qua `VerifyTwoFactorTokenAsync` (loại TOTP authenticator).
4. Nếu hợp lệ → sign-in, trả `AuthResponse`; sai → `401` với thông báo tiếng Việt.

### 6.3 `/api/Auth/login/google`

1. Validate `GoogleLoginRequest` và ID token.
2. Tổng hợp danh sách audience hợp lệ từ cấu hình (`appsettings`, biến môi trường) để xác thực Google token.
3. Dùng `GoogleJsonWebSignature.ValidateAsync` để verify ID token; ném `Unauthorized` nếu token không hợp lệ.
4. Tìm user theo email; nếu chưa có → tạo user mới, set `EmailConfirmed = true`, map `FullName`, `AvatarUrl`.
5. Liên kết `UserLoginInfo` với provider "Google".
6. Đăng nhập user, gọi `BuildAuthResponseAsync` để trả JWT.

## 7. DTO & Response

- `LoginRequest`: hai thuộc tính `UserName`, `Password` (độ dài tối đa 256).
- `GoogleLoginRequest`: chỉ chứa `IdToken` bắt buộc.
- `TwoFaLoginRequest`: gồm `UserId` + `Code`, cả hai đều bắt buộc.
- `AuthResponse` (`Dtos/Auth/AuthResponse.cs`): `token`, `expiresAt`, `user` (dto), danh sách roles.
- `UserMappingExtensions.ToUserDto`: map `ApplicationUser` → DTO trả về cho client (gồm `Id`, `UserName`, `FullName`, `AvatarUrl`, `Roles`).

## 8. Giao tiếp API & ví dụ

### Đăng nhập thường thành công
```http
POST /api/Auth/login
Content-Type: application/json

{
  "userName": "admin",
  "password": "Pass1234!"
}
```
Response `200 OK`:
```json
{
  "token": "<JWT>",
  "expiresAt": "2025-11-30T12:15:30Z",
  "user": {
    "id": "...",
    "username": "admin",
    "email": "admin@example.com",
    "fullName": "Quản trị viên",
    "roles": ["Admin"]
  }
}
```

### Yêu cầu 2FA
```json
{
  "requiresTwoFactor": true,
  "userId": "d5e3..."
}
```

### Đăng nhập Google lỗi cấu hình
`500 InternalServerError` + message "Máy chủ chưa cấu hình đăng nhập Google." (ghi log chi tiết).

## 9. Xử lý lỗi & UX

- Provider ghi lại `ApiException.message` vào `_error`; `LoginScreen` hiển thị snackbar với `_friendlyAuthError`.
- Các thông báo khóa tài khoản, sai mật khẩu, lỗi mạng được chuẩn hóa để người dùng dễ hiểu.
- Khi nhận yêu cầu 2FA, provider không lưu session để đảm bảo chưa đăng nhập.
- Nếu phase đăng nhập thất bại, `_clearSession` xóa token cũ và header bearer.
- Google Sign-In lỗi hiển thị snackbar "Đăng nhập Google thất bại" cùng chi tiết ngoại lệ.

## 10. Kiểm thử đề xuất

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Unit test validator | `flutter_test` | Đảm bảo form bắt buộc nhập và mật khẩu ≥ 6 ký tự |
| AuthProvider login test | `mockito` + fake `AuthService` | Kiểm tra nhánh thành công, thất bại, require 2FA |
| 2FA integration test | `WebApplicationFactory` (.NET) | Verify mã đúng/sai trả mã trạng thái phù hợp |
| Google login mock test | Stub `GoogleJsonWebSignature.ValidateAsync` | Đảm bảo xử lý audience và liên kết user |
| Manual QA | Postman + thiết bị thật | Test account khóa, sai mật khẩu, 2FA, Google |

## 11. Ghi chú triển khai

- Seed bảng `AspNetRoles` để user nhận đúng role sau đăng nhập.
- Cấu hình `Jwt:Issuer`, `Jwt:Audience`, `Jwt:Key` đồng bộ với Flutter (`ApiClient.updateToken`).
- Thiết lập biến môi trường `GOOGLE_CLIENT_ID` hoặc appsettings `Google:ClientId` cho cả backend và Flutter `.env`.
- Nếu bật `TwoFactorEnabled`, đảm bảo người dùng đã cấu hình Authenticator; nên có UI hướng dẫn quét mã.
- Khi đổi payload login backend (ví dụ đổi tên trường), cần cập nhật tương ứng ở `AuthService.loginRaw` và form Flutter.
