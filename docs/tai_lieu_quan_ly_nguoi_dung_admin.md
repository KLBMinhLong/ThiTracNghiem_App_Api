# 🛡️ QUẢN LÝ NGƯỜI DÙNG (ADMIN) - TÀI LIỆU CHI TIẾT

## 1. Luồng tổng quan

```
HomeScreen (icon Admin hiển thị khi AuthProvider.isAdmin == true)
  → Nhấn icon điều hướng tới AdminDashboardScreen
  → AdminDashboardScreen.initState() gọi _loadInitialData()
       → UsersProvider.fetchUsers(page = 1)
       → ChuDeProvider / CauHoiProvider / DeThiProvider / LienHeProvider (các tab khác)
  → Tab "Người dùng" hiển thị mặc định
       → Search + nút "Thêm tài khoản"/"Tải lại"
       → ListView người dùng (PaginatedResponse<User>.items)
          • Nhấn item → _showUserDialog() chỉnh vai trò / khoá
          • Menu ⋮ → Edit / Delete
       → Pull-to-refresh → fetchUsers() với keyword hiện tại
       → Pagination điều hướng trang trước/sau (pageSize = 20)
  → Dialog tạo mới → UsersProvider.createUser() → thêm vào đầu danh sách + reload
  → Dialog quản lý → UsersProvider.updateRoles() + updateStatus()
  → Xoá tài khoản → UsersProvider.deleteUser() → backend kiểm tra quan hệ
```

## 2. Thành phần chính & vị trí mã nguồn

| Thành phần | Mô tả | File |
|------------|-------|------|
| Điều hướng vào dashboard | Icon admin trong `AppBar` (chỉ admin mới thấy) | `thitracnghiemapp/lib/screens/home_screen.dart` (dòng ~70-110) |
| Màn hình tổng admin | NavigationRail / NavigationBar, load dữ liệu | `thitracnghiemapp/lib/screens/admin/admin_dashboard_screen.dart` |
| Tab "Người dùng" | Search, danh sách, phân trang, dialog | `admin_dashboard_screen.dart` (hàm `_buildUsersSection`, `_showUserDialog`, `_showCreateUserDialog`, `_deleteUser`) |
| Provider quản lý người dùng | Fetch, create, update roles/status, delete | `thitracnghiemapp/lib/providers/users_provider.dart` |
| Service gọi API | Wrapper REST `/api/Users` | `thitracnghiemapp/lib/services/users_service.dart` |
| Model người dùng & phân trang | Parse JSON → `User`, `PaginatedResponse` | `thitracnghiemapp/lib/models/user.dart`, `lib/models/paginated_response.dart` |
| Backend controller | CRUD người dùng (Authorize Admin) | `ThiTracNghiemApi/Controllers/UsersController.cs` |
| DTO backend | Request/response body validation | `ThiTracNghiemApi/Dtos/Users/*.cs` |
| Mapping tiện ích | `ApplicationUser` → `UserDto` | `ThiTracNghiemApi/Extensions/UserMappingExtensions.cs` |

## 3. Giao diện & hành vi tab "Người dùng"

- **Header**:
  - Ô tìm kiếm (TextField) lọc theo tên/email; `onSubmitted` gọi `_searchUsers()` (fetch với keyword hiện tại).
  - Nút "Thêm tài khoản" mở dialog tạo user mới.
  - Nút "Tải lại" gọi `_searchUsers()` (reset trạng thái `UsersProvider`).
- **Danh sách**:
  - `RefreshIndicator` → pull-to-refresh cũng gọi `_searchUsers()`.
  - Item `Card` hiển thị avatar (chữ cái đầu), tên/username, email. Gắn badge "Admin" và "Khoá" dựa trên `user.roles` và `user.isLocked`.
  - `PopupMenuButton` với hai action: "Chỉnh sửa" (mở `_showUserDialog`) và "Xoá" (mở `_deleteUser`).
  - Chạm vào toàn bộ card cũng mở `_showUserDialog(user)`.
- **Phân trang**:
  - `_buildPagination()` hiển thị trang hiện tại, nút về trước / kế tiếp.
  - `enabled` dựa trên `PaginatedResponse.isLastPage` và `page > 1`.
  - Khi click, `_userPage` thay đổi và `UsersProvider.fetchUsers()` được gọi với keyword hiện tại.
- **Dialog tạo người dùng** (`_showCreateUserDialog`):
  - Form gồm: Tên đăng nhập (>=3), Email tùy chọn, Họ tên, Mật khẩu (>=6), Checkbox Admin.
  - Xác nhận → gọi `UsersProvider.createUser(...)` với roles `["Admin"]` hoặc `["User"]`.
  - Thành công: snackbar "Đã tạo người dùng" + `_searchUsers()` để đồng bộ trang hiện tại.
- **Dialog quản lý người dùng** (`_showUserDialog`):
  - Checkbox "Quản trị viên" chỉnh roles (chỉ toggle Admin; các role khác nếu có vẫn giữ).
  - Switch "Khoá tài khoản" thay đổi `trangThaiKhoa`.
  - Nút Lưu lần lượt gọi `UsersProvider.updateRoles()` rồi `updateStatus()`; sau khi đóng dialog sẽ `fetchUsers()` lại.
- **Xoá người dùng** (`_deleteUser`):
  - Hộp thoại xác nhận → `UsersProvider.deleteUser(id)`.
  - Thành công: snackbar "Đã xoá người dùng" + reload.
  - Backend chặn xoá nếu tài khoản có lịch sử thi hoặc liên hệ → trả lỗi, snackbar hiển thị `provider.error`.

## 4. Lớp `UsersProvider`

| Hàm | Chức năng | Ghi chú |
|-----|-----------|---------|
| `fetchUsers({keyword, page})` | Gọi service lấy `PaginatedResponse<User>` theo trang | Đặt `_isLoading = true` để UI hiển thị spinner; lưu `_error` nếu có.
| `fetchUserDetail(id)` | Lấy chi tiết một user; dùng cho tab khác (nếu cần) | Cập nhật `_selectedUser`.
| `updateRoles(id, roles)` | PUT `/Users/{id}/roles`; cập nhật danh sách cục bộ | Ghi đè roles hiện tại của user.
| `updateStatus(id, trangThaiKhoa)` | PUT `/Users/{id}/status`; cập nhật khoá/mở khoá | Duy trì danh sách cục bộ đồng bộ.
| `createUser(...)` | POST `/Users`; thêm user mới vào đầu danh sách | Trả về `User?`, cập nhật `total` +1 nếu thành công.
| `deleteUser(id)` | DELETE `/Users/{id}`; loại khỏi danh sách | Giảm `total` khi thành công.
| `clearSelection()` | Reset `_selectedUser` | Hữu ích khi rời tab.

Provider luôn gọi `notifyListeners()` ở mọi nhánh để UI kịp cập nhật.

## 5. Service `UsersService`

- Sử dụng `ApiClient` với JWT từ `AuthProvider`.
- `fetchUsers` gửi query `keyword`, `page`, `pageSize` (mặc định 20). Backend trả `{ total, items }`.
- `updateRoles` PUT body `{ "roles": ["Admin", ...] }`.
- `updateStatus` PUT body `{ "trangThaiKhoa": true/false }`.
- `createUser` POST body gồm `userName`, `email`, `fullName`, `password`, tùy chọn `roles`.
- `deleteUser` gọi DELETE, không trả body.
- Service kiểm tra response phải là `Map<String, dynamic>`; nếu không → throw `ApiException` với thông báo rõ ràng.

## 6. Backend `UsersController`

- `[Authorize(Roles = "Admin")]` trên toàn controller → chỉ admin mới truy cập.
- **GET `/api/Users`**:
  - Hỗ trợ `keyword` (LIKE trên `UserName`, `Email`, `FullName`).
  - Phân trang `page` (>=1), `pageSize` (1..100). Sắp xếp `CreatedAt` giảm dần.
  - Mỗi user map sang `UserDto` + danh sách roles.
- **GET `/api/Users/{id}`**: trả `404` nếu không tìm thấy.
- **PUT `/api/Users/{id}/roles`**:
  - Validate roles tồn tại (`RoleManager.RoleExistsAsync`).
  - Xoá toàn bộ role hiện tại, thêm set mới.
- **PUT `/api/Users/{id}/status`**:
  - Cập nhật `TrangThaiKhoa` và đồng bộ trạng thái lockout của Identity (enable + lock tới `DateTimeOffset.MaxValue` khi khoá; ngược lại mở khoá).
- **POST `/api/Users`**:
  - Kiểm tra trùng username/email.
  - Tạo `ApplicationUser`, `EmailConfirmed = true`.
  - Thêm roles yêu cầu (mặc định "User"). Trả `201 Created` với DTO.
- **DELETE `/api/Users/{id}`**:
  - Không cho xoá nếu tồn tại `KetQuaThi` hoặc `LienHe` liên kết.
  - Xoá trước các bình luận (`BinhLuans.ExecuteDeleteAsync`).
  - Cuối cùng xoá user (`UserManager.DeleteAsync`).

## 7. Định dạng API mẫu

### Lấy danh sách người dùng
```http
GET /api/Users?keyword=nguyen&page=1&pageSize=20
Authorization: Bearer <JWT-admin>
```
Response:
```json
{
  "total": 42,
  "items": [
    {
      "id": "...",
      "userName": "admin",
      "email": "admin@example.com",
      "fullName": "Quản trị viên",
      "trangThaiKhoa": false,
      "createdAt": "2025-06-01T10:20:00Z",
      "roles": ["Admin"]
    }
  ]
}
```

### Cập nhật role & khoá tài khoản
```http
PUT /api/Users/{id}/roles
Authorization: Bearer <JWT-admin>
Content-Type: application/json

{ "roles": ["Admin"] }
```
```http
PUT /api/Users/{id}/status
Authorization: Bearer <JWT-admin>
Content-Type: application/json

{ "trangThaiKhoa": true }
```

### Tạo người dùng mới
```http
POST /api/Users
Authorization: Bearer <JWT-admin>
Content-Type: application/json

{
  "userName": "giaovien001",
  "email": "teacher@example.com",
  "fullName": "Giáo viên 001",
  "password": "Passw0rd!",
  "roles": ["User"]
}
```

## 8. Xử lý lỗi & tình huống đặc biệt

- Backend trả `400 BadRequest` khi:
  - Username/email trùng; hiển thị snackbar với thông báo từ `_error` của provider.
  - Role không tồn tại; nên đảm bảo client chỉ gửi `Admin`/`User`.
  - Xoá user có dữ liệu liên quan → hiển thị thông báo "Không thể xoá tài khoản vì có lịch sử thi hoặc liên hệ liên quan.".
- `UsersProvider.updateRoles` và `updateStatus` chạy nối tiếp không kiểm tra lỗi giữa chừng → nếu cập nhật roles thành công nhưng khoá thất bại, roles vẫn đã đổi. Cân nhắc bổ sung rollback hoặc hiển thị thông báo rõ.
- UI hiển thị `CircularProgressIndicator` nếu `_isLoading` true và chưa có dữ liệu.
- Với danh sách lớn, pagination dựa vào `pageSize=20`; nếu cần tải nhiều hơn, chỉnh tham số khi gọi service.

## 9. Kiểm thử đề xuất

| Kiểm thử | Công cụ | Mục tiêu |
|----------|---------|----------|
| Unit test `UsersProvider` | `flutter_test` với mock `UsersService` | Đảm bảo create/update/delete cập nhật `PaginatedResponse` đúng cách và xử lý `_error`.
| Widget test `_buildUsersSection` | `pumpWidget` với provider giả | Kiểm tra search, badge hiển thị, popup menu và pagination hoạt động.
| API integration test | ASP.NET `WebApplicationFactory` | Kiểm chứng role-based authorize, validation (username/email trùng, role không tồn tại, lock/unlock) và chặn xoá khi có dữ liệu liên quan.
| Manual QA | Thiết bị thật + tài khoản admin | Thử tạo user, đổi role, khoá/mở, xoá user chưa có dữ liệu; xác nhận trạng thái duy trì sau khi reload app.

## 10. Ghi chú triển khai

- Chỉ tài khoản có role "Admin" mới thấy icon điều hướng và gọi được API (JWT phải chứa claim role).
- Khi mở rộng danh sách role, cập nhật cả UI (checkbox/selector) lẫn kiểm tra phía server.
- Để tránh double-request khi lưu (roles + status), có thể hợp nhất API backend thành endpoint duy nhất hoặc chờ kết quả từng bước trước khi gọi bước tiếp theo.
- Xem xét log hoạt động admin (audit) nếu cần truy vết thay đổi role/khoá tài khoản.
- Nếu số lượng người dùng rất lớn, cân nhắc thêm filter nâng cao (vai trò, trạng thái khoá) và bảng dữ liệu thay vì card.
