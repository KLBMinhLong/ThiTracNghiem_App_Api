# 👤 QUẢN LÝ HỒ SƠ NGƯỜI DÙNG - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng

```
Người dùng mở tab "Tài khoản" trong HomeScreen
  → Xem thông tin profile (avatar, họ tên, email)
  → Thao tác:
      - Chỉnh sửa thông tin cá nhân → show bottom sheet → AuthProvider.updateProfile() → PUT /api/Auth/me
      - Đổi mật khẩu → show dialog → AuthProvider.changePassword() → PUT /api/Auth/me/password
      - Đăng xuất → AuthProvider.logout() → clear TokenStorage → quay về Login
      - Bật/Tắt 2FA → (đồng tài liệu 2FA)
      - Chuyển theme dark/light → ThemeProvider.toggleTheme()
-> Profile card luôn phản ánh `auth.currentUser`
```

## 2. Thành phần & vị trí mã nguồn

| Bước | Mô tả | File & dòng |
|------|-------|-------------|
| 1 | UI tab "Tài khoản" | `lib/screens/home_screen.dart` class `_ProfileTab` (dòng 1584-2040) |
| 2 | Sheet chỉnh sửa thông tin | `_showEditProfile` + `_EditProfileSheet` trong `home_screen.dart` (dòng 1210-1420) |
| 3 | Dialog đổi mật khẩu | `_showChangePassword` + `_ChangePasswordDialog` trong `home_screen.dart` (dòng 1422-1570) |
| 4 | Đăng xuất | `_confirmLogout` (`home_screen.dart`, dòng 76-118) |
| 5 | Provider cập nhật profile | `lib/providers/auth_provider.dart` (`updateProfile`, dòng 230-248) |
| 6 | Provider đổi mật khẩu | `auth_provider.dart` (`changePassword`, dòng 250-286) |
| 7 | Provider logout | `auth_provider.dart` (`logout`, dòng 306-313) |
| 8 | API cập nhật profile | `ThiTracNghiemApi/Controllers/AuthController.cs` (`UpdateProfile`, dòng 502-571) |
| 9 | API đổi mật khẩu | `AuthController.ChangePassword`, dòng 573-636 |
| 10 | DTO profile | `ThiTracNghiemApi/Dtos/Auth/UserDto.cs` & `UserMappingExtensions.cs` |
| 11 | TokenStorage | `lib/core/token_storage.dart` (đọc/ghi session khi cập nhật)

> Số dòng dựa trên repo ngày 31/10/2025.

## 3. UI chi tiết

### 3.1 Thẻ thông tin người dùng
- Hiển thị avatar (chữ cái đầu họ tên), họ tên, email.
- Dữ liệu lấy từ `auth.currentUser` (model `User`).
- Họ tên lấy `user.fullName` nếu có, fallback `user.userName`.

### 3.2 Các mục thao tác
- **Chỉnh sửa thông tin**: mở bottom sheet `_EditProfileSheet`.
  - Form trường: Họ và tên (bắt buộc), Email (bắt buộc, validator), Số điện thoại (tùy chọn), Ngày sinh (date picker), Giới tính.
  - Nút `Lưu thay đổi` gọi `AuthProvider.updateProfile`.
  - Thành công: đóng sheet, UI cập nhật do provider notify listeners. Lỗi: hiển thị snackbar.

- **Đổi mật khẩu**: mở `_ChangePasswordDialog` (AlertDialog).
  - Trường nhập: Mật khẩu hiện tại, Mật khẩu mới, Xác nhận mật khẩu mới.
  - Kiểm tra mật khẩu mới tối thiểu 6 ký tự & trùng khớp confirm.
  - Gọi `AuthProvider.changePassword`, hiển thị snackbar theo kết quả.

- **Chế độ tối**: `SwitchListTile` gọi `ThemeProvider.toggleTheme`, lưu `SharedPreferences`.

- **Thống kê kết quả**: điều hướng tới `StatisticsScreen` (phiên riêng).

- **Đăng xuất**: gọi `_confirmLogout` → `AuthProvider.logout` → chuyển tới `LoginScreen`.

- **Xác thực 2 bước**: `_TwoFaTile` (tham khảo tài liệu riêng).

## 4. Provider (AuthProvider)

### 4.1 `updateProfile`
- Yêu cầu user đã đăng nhập (`isAuthenticated`), nếu không ném `ApiException` "Bạn chưa đăng nhập".
- Gọi `AuthService.updateProfile` với các trường tùy chọn (nullable → bỏ qua nếu null).
- Cập nhật `_currentUser` = kết quả trả về.
- Gọi `_updateCachedUser` để ghi lại session vào `TokenStorage` (tránh lệch thông tin giữa bộ nhớ và storage).
- `notifyListeners()` để UI rebuild.

### 4.2 `changePassword`
- Kiểm tra `isAuthenticated`.
- Gọi `AuthService.changePassword` với `{ currentPassword, newPassword }`.
- Nếu `ApiException` → gán `_error` và return false; thành công return true.

### 4.3 `logout`
- Gọi `_clearSession()` (xóa token, user, error, cập nhật ApiClient token null, clear storage).
- `notifyListeners()` → UI detect logged out state.

## 5. Service (AuthService)

| Hàm | HTTP | Endpoint | Payload |
|-----|------|----------|---------|
| `updateProfile` | PUT | `/api/Auth/me` | `{ fullName?, email?, soDienThoai?, ngaySinh?, gioiTinh?, avatarUrl? }` |
| `changePassword` | PUT | `/api/Auth/me/password` | `{ currentPassword, newPassword }` |

- Cả hai expect response JSON (profile mới) hoặc `204`.
- Sử dụng `ApiClient.put` – throw `ApiException` nếu response không phải Map hoặc status ≥ 400.

## 6. Backend Controller

### 6.1 `UpdateProfile` (`PUT /api/Auth/me`)
1. `[Authorize]` – lấy user hiện tại.
2. Body: `UpdateProfileRequest` (fullName, email, soDienThoai, ngaySinh, gioiTinh, avatarUrl).
3. Validate email không rỗng nếu cung cấp (không attribute `[EmailAddress]` – cần QC).
4. Cập nhật các trường vào `ApplicationUser` (trim, null-check). Đặc biệt:
   - `Email` thay đổi => check trùng & set `EmailConfirmed = false` nếu cần (nếu logic bổ sung).
   - `NgaySinh`, `GioiTinh`, `SoDienThoai`, `AvatarUrl` gán trực tiếp.
5. Gọi `_userManager.UpdateAsync(user)`.
6. Trả `UserDto` thông qua `user.ToUserDto(_userManager)` (bao gồm roles).

### 6.2 `ChangePassword` (`PUT /api/Auth/me/password`)
1. Body: `ChangePasswordRequest` (`CurrentPassword`, `NewPassword` ≥ 6).
2. Gọi `_userManager.ChangePasswordAsync(user, currentPassword, newPassword)`.
3. Nếu lỗi (mật khẩu cũ sai, password policy) → add `IdentityError` vào `ModelState` và trả `ValidationProblem`.
4. Thành công → `NoContent()`.

## 7. API mẫu

### Cập nhật profile
```http
PUT /api/Auth/me
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "fullName": "Nguyễn Văn A",
  "email": "a.nguyen@example.com",
  "soDienThoai": "0912345678",
  "ngaySinh": "1998-04-12T00:00:00Z",
  "gioiTinh": "Nam"
}
```
Response `200 OK`:
```json
{
  "id": "...",
  "username": "nguyenvana",
  "email": "a.nguyen@example.com",
  "fullName": "Nguyễn Văn A",
  "avatarUrl": null,
  "roles": ["User"],
  "trangThaiKhoa": false
}
```

### Đổi mật khẩu
```http
PUT /api/Auth/me/password
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "currentPassword": "OldPass123",
  "newPassword": "NewPass456!"
}
```
Response `204 NoContent`

### Đăng xuất (client)
- Không có endpoint riêng; client xóa token & session.

## 8. Xử lý lỗi & UX

- Nếu `updateProfile` trả lỗi (ví dụ email trùng) → `_EditProfileSheet` snackbar hiển thị `auth.error!`.
- `changePassword` trả `ValidationProblem` → provider gán `_error` = message, dialog hiển thị "Đổi mật khẩu thất bại".
- `logout` đảm bảo xóa token khỏi storage để lần mở app sau không auto login.
- Khi profile update thành công, session cập nhật → ensure `AuthProvider.initialize` sau này tải thông tin mới.

## 9. Kiểm thử đề xuất

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Unit test provider | `mockito` | Đảm bảo `updateProfile` cập nhật `_currentUser`, `TokenStorage` |
| API integration test | `WebApplicationFactory` | PUT `/Auth/me` với email trùng, password sai, validate response |
| UI widget test | `flutter_test` | Validate form (bỏ trống họ tên/email) |
| Manual QA | Thiết bị thật | Cập nhật profile, đổi mật khẩu, đăng xuất & đăng nhập lại kiểm tra |

## 10. Ghi chú triển khai

- Đảm bảo identity policy (mật khẩu) trùng khớp client validator (>=6 ký tự, gợi ý: thêm yêu cầu ký tự đặc biệt nếu backend bật).
- Nếu cho phép đổi email, cân nhắc yêu cầu xác nhận email mới (hiện chưa triển khai).
- Có thể mở rộng `AvatarUrl` với upload ảnh (hiện chỉ là string URL).
- Khi logout, cần clear các provider khác nếu phụ thuộc `currentUser` (hiện `logout()` chỉ clear Auth session).
- Bật `TwoFactorEnabled` hoặc roles thay đổi → `AuthProvider.refreshProfile()` có thể dùng để đồng bộ.
