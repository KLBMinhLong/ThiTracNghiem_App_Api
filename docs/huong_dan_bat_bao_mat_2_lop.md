# 🔐 BẬT/TẮT XÁC THỰC 2 BƯỚC (2FA) - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng thao tác

```
Người dùng mở tab "Tài khoản" trong HomeScreen → Switch "Chế độ 2FA"
  Nếu bật:
    _TwoFaTile.onToggle(true) → AuthProvider.setupTwoFa() → AuthService.setupTwoFa() →
    GET /api/Auth/2fa/setup → AuthController.SetupTwoFa() → trả sharedKey + QR →
    UI hiển thị QR + yêu cầu nhập mã 6 số → AuthProvider.enableTwoFa(code)
      → AuthService.enableTwoFa(code) → POST /api/Auth/2fa/enable → Thành công → cập nhật trạng thái
  Nếu tắt:
    _TwoFaTile.onToggle(false) → AuthProvider.disableTwoFa() →
    AuthService.disableTwoFa() → POST /api/Auth/2fa/disable → cập nhật trạng thái

Trước khi hiển thị switch, widget gọi AuthProvider.getTwoFaStatus() → GET /api/Auth/2fa/status.
```

## 2. Thành phần & vị trí mã nguồn

| Bước | Mô tả | File & dòng |
|------|-------|-------------|
| 1 | UI hiển thị toggle & xử lý dialog quét mã | `lib/screens/home_screen.dart` class `_TwoFaTile` (dòng 2060-2230) |
| 2 | Provider tải trạng thái, bật/tắt 2FA | `lib/providers/auth_provider.dart` (`getTwoFaStatus`, `setupTwoFa`, `enableTwoFa`, `disableTwoFa` – dòng 288-328) |
| 3 | Service gọi API 2FA | `lib/services/auth_service.dart` (`getTwoFaStatus`, `setupTwoFa`, `enableTwoFa`, `disableTwoFa` – dòng 162-187) |
| 4 | DTO trả về từ backend | `ThiTracNghiemApi/Dtos/Auth/TwoFaDtos.cs` (dòng 4-35) |
| 5 | Endpoint lấy trạng thái | `ThiTracNghiemApi/Controllers/AuthController.cs` (`GetTwoFaStatus`, dòng 410-422) |
| 6 | Endpoint setup (lấy QR + key) | `AuthController.SetupTwoFa` (dòng 424-460) |
| 7 | Endpoint bật 2FA | `AuthController.EnableTwoFa` (dòng 462-487) |
| 8 | Endpoint tắt 2FA | `AuthController.DisableTwoFa` (dòng 489-500) |
| 9 | Thư viện QR trên UI | `qr_flutter` sử dụng trong `_showEnableDialog` (`home_screen.dart`, dòng 2140-2170) |

> Số dòng tham chiếu theo trạng thái repo ngày 31/10/2025. Nếu file thay đổi, tìm theo tên hàm tương ứng.

## 3. Giao diện người dùng (Flutter)

- `HomeScreen` tab "Tài khoản" chứa `SwitchListTile` (chữ **"Xác thực 2 bước (2FA)"**) trong `_TwoFaTile`.
- Khi widget khởi tạo, `_load()` gọi `AuthProvider.getTwoFaStatus()` để cập nhật `_enabled`.
- Bật 2FA:
  - Hiển thị `AlertDialog` gồm QR code (vẽ bằng `qr.QrImageView`), link `otpauth://` và khóa `sharedKey` để nhập thủ công.
  - Người dùng nhập mã 6 số từ ứng dụng Google Authenticator. Mã gửi vào `AuthProvider.enableTwoFa`.
  - Thành công → dialog đóng, snackbar "Đã bật xác thực 2 bước" hiển thị.
- Tắt 2FA: switch gọi trực tiếp `AuthProvider.disableTwoFa` không yêu cầu xác nhận mã.
- Nếu call API lỗi → snackbar hiển thị thông báo tiếng Việt tương ứng.

## 4. Provider (AuthProvider)

| Hàm | Chức năng | Ghi chú |
|-----|-----------|---------|
| `getTwoFaStatus()` | Gửi `GET /api/Auth/2fa/status` → trả bool | Bắt lỗi `ApiException`, set `_error`, trả `false` |
| `setupTwoFa()` | Gửi `GET /api/Auth/2fa/setup` → nhận `TwoFaSetupResponse` | Trả về `sharedKey`, `authenticatorUri`, trạng thái `enabled` |
| `enableTwoFa(code)` | `POST /api/Auth/2fa/enable` với `{ code }` | Ném lỗi ra ngoài để UI hiển thị (không nuốt lỗi) |
| `disableTwoFa()` | `POST /api/Auth/2fa/disable` | Nếu lỗi → notify listeners, rethrow |

Các hàm đều cập nhật `_error` và `notifyListeners()` để UI phản ứng (loading spinner ở switch).

## 5. Service (AuthService)

- `getTwoFaStatus` → `GET /api/Auth/2fa/status`, đọc `enabled` từ JSON.
- `setupTwoFa` → `GET /api/Auth/2fa/setup`, parse `TwoFaSetupResponse` (sharedKey, authenticatorUri, enabled).
- `enableTwoFa` → `POST /api/Auth/2fa/enable` với body `{ "code": "123456" }`.
- `disableTwoFa` → `POST /api/Auth/2fa/disable` không body.
- Tất cả sử dụng `ApiClient` để tự động thêm header Bearer token và xử lý lỗi HTTP ≥ 400 thành `ApiException`.

## 6. Backend Controller

1. **`GetTwoFaStatus`** (`[Authorize] GET /api/Auth/2fa/status`)
   - Lấy user hiện tại bằng `GetCurrentUserEntityAsync()`.
   - Trả về `TwoFaStatusResponse { enabled = user.TwoFactorEnabled }`.

2. **`SetupTwoFa`** (`[Authorize] GET /api/Auth/2fa/setup`)
   - Lấy user, đảm bảo có authenticator key (`ResetAuthenticatorKeyAsync` nếu chưa có).
   - Format key (`FormatKey`) và tạo URI `otpauth://` (`GenerateOtpAuthUri`).
   - Trả `TwoFaSetupResponse` gồm `SharedKey`, `AuthenticatorUri`, `Enabled`.

3. **`EnableTwoFa`** (`[Authorize] POST /api/Auth/2fa/enable`)
   - Validate `TwoFaEnableRequest` (code bắt buộc).
  - Chuẩn hóa code (loại bỏ khoảng trắng, dấu `-`).
  - `VerifyTwoFactorTokenAsync` so sánh với seed của user.
  - Nếu hợp lệ → `SetTwoFactorEnabledAsync(user, true)` và trả `204 NoContent`.

4. **`DisableTwoFa`** (`[Authorize] POST /api/Auth/2fa/disable`)
   - Đặt `TwoFactorEnabled = false`, trả `204 NoContent`.

## 7. API mẫu & phản hồi

### Lấy trạng thái
```http
GET /api/Auth/2fa/status
Authorization: Bearer <JWT>
```
Response:
```json
{ "enabled": true }
```

### Lấy QR & khóa
```http
GET /api/Auth/2fa/setup
Authorization: Bearer <JWT>
```
Response:
```json
{
  "sharedKey": "abcd efgh ijkl",
  "authenticatorUri": "otpauth://totp/SmartTest:user%40mail.com?secret=ABCDEF...",
  "enabled": false
}
```

### Bật 2FA
```http
POST /api/Auth/2fa/enable
Authorization: Bearer <JWT>
Content-Type: application/json

{ "code": "123456" }
```
Response: `204 NoContent`

### Tắt 2FA
```http
POST /api/Auth/2fa/disable
Authorization: Bearer <JWT>
```
Response: `204 NoContent`

## 8. Xử lý lỗi & UX

- Nếu gọi API setup/enable thất bại → snackbar hiển thị `Không thể bật 2FA: <error>`.
- `enableTwoFa` ném ngoại lệ nếu mã sai → UI hiển thị `Mã không hợp lệ: ...`.
- Khi `getTwoFaStatus` lỗi (ví dụ token hết hạn) → `_enabled` về `false`, switch hiển thị trạng thái tắt.
- Dialog không dispose `TextEditingController` ngay để tránh race condition trong rebuild (ghi chú trong code).

## 9. Kiểm thử đề xuất

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Unit test provider | `mockito` mock `AuthService` | Đảm bảo `getTwoFaStatus`, `enableTwoFa`, `disableTwoFa` xử lý lỗi & notify listeners |
| Integration API test | `WebApplicationFactory` | Verify `/2fa/setup` trả đúng sharedKey, `/2fa/enable` bật cờ `TwoFactorEnabled` |
| Manual QA | Thiết bị thật + Google Authenticator | Quét QR, nhập mã, đăng nhập lại để xác minh yêu cầu mã 6 số |
| Error handling | Bật rồi nhập mã sai | Đảm bảo server trả 400/401 và UI hiển thị thông báo |

## 10. Ghi chú triển khai

- Cần cấu hình `IdentityOptions.SignIn.RequireConfirmedEmail` và thời gian hiệu lực token OTP (mặc định 30s) nếu muốn thay đổi.
- App cần cài `google_authenticator` hoặc ứng dụng TOTP tương thích để người dùng quét QR.
- `AuthenticatorUri` chứa issuer lấy từ `appsettings.json` (`Jwt:Issuer`), nên đồng bộ với brand.
- Khi bật 2FA, luồng đăng nhập thường phải xử lý `requiresTwoFactor = true` (đã mô tả trong doc đăng nhập).
- Nên cung cấp hướng dẫn người dùng sao lưu mã dự phòng (hiện chưa triển khai, có thể bổ sung sau).
