# 📨 CHỨC NĂNG QUÊN MẬT KHẨU - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng

```
Bước 1 (Yêu cầu mã):
ForgotPasswordScreen → AuthProvider.sendPasswordResetEmail() → AuthService.forgotPassword() →
POST /api/Auth/forgot-password → AuthController.ForgotPassword() → SendEmail → 202 Accepted

Bước 2 (Đặt lại mật khẩu):
ForgotPasswordScreen → AuthProvider.resetPassword() → AuthService.resetPassword() →
POST /api/Auth/reset-password → AuthController.ResetPassword() → UserManager.ResetPasswordAsync
```

## 2. Thành phần & vị trí mã nguồn

| Bước | Mô tả | File & dòng |
|------|-------|-------------|
| 1 | UI nhập email, token, mật khẩu mới | `lib/screens/forgot_password_screen.dart` (dòng 18-380) |
| 2 | Gửi email/reset token từ UI | `_submitEmail`, `_submitReset` trong `forgot_password_screen.dart` (dòng 336-373) |
| 3 | Provider gửi email | `lib/providers/auth_provider.dart` (`sendPasswordResetEmail`, dòng 330-353) |
| 4 | Provider đặt lại mật khẩu | `auth_provider.dart` (`resetPassword`, dòng 355-383) |
| 5 | Service gọi API forgot password | `lib/services/auth_service.dart` (dòng 146-150) |
| 6 | Service gọi API reset password | `auth_service.dart` (dòng 152-160) |
| 7 | Endpoint `/forgot-password` | `ThiTracNghiemApi/Controllers/AuthController.cs` (dòng 88-142) |
| 8 | Endpoint `/reset-password` | `AuthController.cs` (dòng 144-188) |
| 9 | DTO yêu cầu | `Dtos/Auth/ForgotPasswordRequest.cs`, `Dtos/Auth/ResetPasswordRequest.cs` |
| 10 | Gửi email SMTP | `Services/SmtpEmailSender.cs` (dùng bởi controller thông qua `IEmailSender`) |
| 11 | Cấu hình link reset | `appsettings.json` key `Frontend:ResetPasswordUrl`

> Số dòng tham chiếu theo commit ngày 31/10/2025. Khi file thay đổi, hãy tìm theo tên hàm tương ứng.

## 3. Giao diện người dùng (Flutter)

- `ForgotPasswordScreen` trình bày hai card: "Bước 1: Yêu cầu đặt lại" và "Bước 2: Đặt mật khẩu mới".
- Form bước 1 yêu cầu email hợp lệ, nút "Gửi mã" disable khi `_sendingResetEmail` để tránh double-click.
- Form bước 2 yêu cầu token, mật khẩu mới (>= 6 ký tự) và xác nhận trùng khớp; nút "Đặt lại mật khẩu" disable khi đang xử lý.
- `_emailSent` quyết định hiển thị hint "Yêu cầu mã ở bước 1".
- SnackBar hiển thị phản hồi thành công/thất bại thông qua helper `UIHelpers.showSuccessSnackBar` và `showErrorSnackBar`.

## 4. Provider (AuthProvider)

### 4.1 `sendPasswordResetEmail`
- Chặn gửi trùng bằng `_sendingResetEmail` flag.
- Gọi `AuthService.forgotPassword` với email đã trim.
- Thành công trả `null` cho UI; lỗi trả chuỗi message từ `ApiException` hoặc `Exception`.
- Luôn reset flag và `notifyListeners()` để cập nhật nút loading.

### 4.2 `resetPassword`
- Tương tự, dùng `_resettingPassword` để chặn spam.
- Gọi `AuthService.resetPassword` với email, token, mật khẩu mới.
- Backend trả lỗi → provider chuyển nguyên message về UI.
- Không động tới session vì user chưa đăng nhập trong flow này.

## 5. Service (AuthService)

- `forgotPassword` gửi `POST /api/Auth/forgot-password` với `{ "email": email }`. Không parse nội dung vì backend trả `202 Accepted` hoặc lỗi.
- `resetPassword` gửi `POST /api/Auth/reset-password` với `{ "email": email, "token": token, "newPassword": newPassword }`.
- Cả hai hưởng lợi từ `ApiClient` để encode JSON, xử lý HTTP status >= 400 thành `ApiException`.

## 6. Backend Controller

### 6.1 `/api/Auth/forgot-password`
1. Validate `ForgotPasswordRequest` (`[Required][EmailAddress]`).
2. Tìm user theo email; nếu không tồn tại vẫn trả `202 Accepted` để tránh lộ thông tin.
3. Sinh token qua `GeneratePasswordResetTokenAsync`, encode Base64Url.
4. Nếu cấu hình `Frontend:ResetPasswordUrl` có giá trị → dựng link reset (gồm query `email`, `token`). Nếu không → gửi token thô.
5. Soạn email thân thiện bằng `StringBuilder`, gửi qua `_emailSender`.
6. Nếu gửi email lỗi → log và trả `500 InternalServerError` với thông báo tiếng Việt.
7. Thành công trả `202 Accepted` với message chung chung.

### 6.2 `/api/Auth/reset-password`
1. Validate `ResetPasswordRequest` (`Email`, `Token`, `NewPassword` ≥ 6 ký tự).
2. Tìm user theo email; nếu không có → `400 BadRequest`.
3. Decode token Base64Url; lỗi decode → `400 BadRequest`.
4. Gọi `ResetPasswordAsync`; nếu có lỗi Identity → populate `ModelState` và trả `ValidationProblem`.
5. Thành công trả `200 OK` với thông báo.

## 7. DTO & Email Template

- `ForgotPasswordRequest`: `Email` bắt buộc, `[EmailAddress]` để ASP.NET tự validate.
- `ResetPasswordRequest`: gồm `Email`, `Token`, `NewPassword` với `[MinLength(6)]` và thông báo tiếng Việt.
- Email gửi ra chứa: lời chào, mô tả yêu cầu, link hoặc mã token, hướng dẫn bỏ qua nếu không yêu cầu, chữ ký "Thi Trắc Nghiệm Team".

## 8. Giao tiếp API & ví dụ

### Yêu cầu mã đặt lại
```http
POST /api/Auth/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```
Response `202 Accepted` (dù email tồn tại hay không):
```json
{
  "message": "Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi."
}
```

### Đặt lại mật khẩu
```http
POST /api/Auth/reset-password
Content-Type: application/json

{
  "email": "user@example.com",
  "token": "<Base64UrlEncodedToken>",
  "newPassword": "Pass1234!"
}
```
Response `200 OK`:
```
"Đã đặt lại mật khẩu thành công."
```

### Các lỗi thường gặp
- `400 BadRequest`: Email không tồn tại, token sai định dạng, hoặc mật khẩu mới không đạt yêu cầu.
- `500 InternalServerError`: Gửi email thất bại (xem log Serilog để điều tra SMTP).

## 9. Xử lý lỗi & UX

- UI disable nút khi provider đang gửi để tránh lặp.
- `AuthProvider` trả message tiếng Việt; UI hiển thị snackbar theo từng bước.
- `_emailSent` bật khi bước 1 thành công, nhắc người dùng sử dụng token đã nhận.
- Nếu backend không cấu hình `Frontend:ResetPasswordUrl`, email sẽ cung cấp token thủ công; UI hiện tại chấp nhận token copy dán.

## 10. Môi trường & cấu hình

- SMTP cấu hình trong `appsettings.json` (`SmtpOptions`) và script `set_smtp_env.bat`.
- Biến `Frontend:ResetPasswordUrl` trỏ tới trang web/route reset (ví dụ `https://smarttest.app/reset-password`). Nếu không đặt, người dùng sử dụng token trong app.
- Đảm bảo client Flutter encode token đúng (giữ nguyên Base64Url); không decode/encode lại trước khi gửi `reset-password`.
- Kiểm tra thư rác/spam khi test email thật.

## 11. Kiểm thử đề xuất

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Unit test validator UI | `flutter_test` | Đảm bảo email/token/password validation hoạt động |
| Provider tests | `mockito` fake `AuthService` | Kiểm tra flag `_sendingResetEmail`, `_resettingPassword` |
| API integration test | `WebApplicationFactory` (.NET) | Verify responses (202, 400, 500) và token decode |
| Email delivery test | SMTP sandbox (Mailpit, Mailhog) | Đảm bảo template, link/token đúng |
| End-to-end manual | Thiết bị thật + Postman | Kiểm tra flow hoàn chỉnh với email thực |

## 12. Ghi chú triển khai

- Token được encode Base64Url; khi copy từ email, cần giữ nguyên, không thêm dấu cách.
- Nếu triển khai web reset page, đảm bảo nó gửi lại token Base64Url y hệt cho endpoint `/reset-password`.
- Nên đặt expiry mặc định cho token (Identity dùng default 1 giờ). Có thể điều chỉnh trong `IdentityOptions.Password` cấu hình `TokenOptions` nếu cần.
- Khi đổi template email, giữ lại biến `resetBaseUrl` logic để tránh phá vỡ link.
