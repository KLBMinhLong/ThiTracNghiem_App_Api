# 📝 QUẢN LÝ ĐỀ THI (ADMIN) - TÀI LIỆU CHI TIẾT

## 1. Luồng tổng quan

```
HomeScreen (icon Admin hiển thị nếu AuthProvider.isAdmin)
  → Nhấn → AdminDashboardScreen
  → initState() gọi _loadInitialData()
      ↳ DeThiProvider.fetchAdminDeThis(page = 1)
      ↳ DeThiProvider.fetchOpenDeThis() (phục vụ phía client)
      ↳ ChuDeProvider.fetchChuDes() cho dropdown
      ↳ Các provider khác (Users, Questions, Contacts)
  → Tab "Đề thi" (_buildExamsSection)
      ↳ Search + nút Lọc + nút "Thêm đề thi"
      ↳ Bộ lọc chủ đề, trạng thái, nút "Xoá lọc"
      ↳ Danh sách đề thi (card) + phân trang `_buildPagination`
      ↳ Popup menu từng đề thi: "Sửa" (→ `_showExamDialog`), "Xóa" (→ `_deleteExam`)
      ↳ Dialog thêm/cập nhật kiểm tra form, cho phép bật `allowMultipleAttempts`
      ↳ Xoá đề thi kiểm tra backend (chặn khi có kết quả thi liên quan)
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File |
|------------|---------|------|
| UI tab đề thi | Search/filter/list/pagination | `thitracnghiemapp/lib/screens/admin/admin_dashboard_screen.dart` (`_buildExamsSection`) |
| Dialog thêm/cập nhật | Thu thập dữ liệu form | `admin_dashboard_screen.dart` (`_showExamDialog`) |
| Xoá đề thi | Xác nhận & gọi provider | `admin_dashboard_screen.dart` (`_deleteExam`) |
| Provider đề thi | Giữ danh sách open/admin, CRUD | `thitracnghiemapp/lib/providers/de_thi_provider.dart` |
| Service REST | Gọi `/api/DeThi`, `/api/DeThi/open` | `thitracnghiemapp/lib/services/de_thi_service.dart` |
| Model Flutter | `DeThi`, `allowMultipleAttempts`, `isOpen` | `thitracnghiemapp/lib/models/de_thi.dart` |
| Backend controller | CRUD, lọc mở, phân trang | `ThiTracNghiemApi/Controllers/DeThiController.cs` |
| Entity EF Core | Bảng `DeThis`, trường `AllowMultipleAttempts` | `ThiTracNghiemApi/Models/DeThi.cs` |

> Dữ liệu dựa trên nhánh `main` ngày 31/10/2025.

## 3. Giao diện & hành vi tab "Đề thi"

### 3.1 Thanh tìm kiếm & bộ lọc
- **Ô tìm kiếm** (`_examKeywordController`): lọc theo `tenDeThi` (lowercase). Khi clear text (icon `x`), danh sách cập nhật tức thì.
- **Nút "Lọc"**: bật tắt vùng filter mở rộng.
- **Filter chủ đề** (`_examTopicFilterId`): dropdown từ `ChuDeProvider.chuDes`. Null = tất cả.
- **Filter trạng thái** (`_examStatusFilter`): `Mo` (Mở) hoặc `Dong` (Đóng). Null = tất cả.
- **Nút "Xoá lọc"**: reset keyword + dropdown.

### 3.2 Danh sách đề thi
- Lấy dữ liệu từ `examProvider.adminDeThis?.items`. Có thể khác với tổng `total` do filter cục bộ.
- Card hiển thị:
  - Tên đề thi (bold), badge trạng thái (Mở/Đóng).
  - Chủ đề, số câu, thời gian thi (phút).
- Popup menu `⋮` với hai hành động: "Sửa" → `_showExamDialog(exam)`; "Xóa" → `_deleteExam(exam.id)`.
- Khi `loadingAdmin` true → spinner; khi danh sách rỗng → hiển thị trạng thái với gợi ý tìm kiếm/thêm mới.
- Phân trang (`_examPage`): `_buildPagination` gọi `fetchAdminDeThis(page)` khi chuyển trang.

### 3.3 Dialog thêm/cập nhật (`_showExamDialog`)
- Form gồm:
  - Dropdown chủ đề (bắt buộc, default = chủ đề đầu tiên nếu có).
  - `Tên đề thi`, `Số câu hỏi`, `Thời gian thi` (validator: không rỗng, số hợp lệ).
  - Dropdown trạng thái (`Mo`, `Dong`).
  - Checkbox "Cho phép thí sinh thi nhiều lần" (`allowMultipleAttempts`).
- Khi nhấn "Lưu": dialog trả `_ExamDialogResult`.
  - Nếu `isUpdate`: gọi `examProvider.updateDeThi(...)`.
  - Nếu tạo mới: `examProvider.createDeThi(...)`.
- Sau khi provider hoàn tất, gọi `fetchAdminDeThis(page: _examPage)` để đồng bộ danh sách và snackbar thông báo.

### 3.4 Xoá đề thi (`_deleteExam`)
- Hiển thị AlertDialog xác nhận.
- `examProvider.deleteDeThi(id)` → backend sẽ chặn nếu có kết quả thi (`KetQuaThi`) liên quan.
- Dù thành công hay thất bại, đều reload lại trang hiện tại (`fetchAdminDeThis`).
- Snackbar hiển thị kết quả (thành công hoặc thông báo lỗi từ `examProvider.error`).

## 4. Provider `DeThiProvider`

| Thuộc tính | Ý nghĩa |
|------------|---------|
| `_openDeThis` | Danh sách đề thi đang mở cho người dùng thường |
| `_adminDeThis` | `PaginatedResponse<DeThi>` cho tab admin |
| `_loadingOpen`, `_loadingAdmin` | Cờ hiển thị spinner |
| `_error` | Lưu thông báo lỗi cuối cùng |

| Hàm | Chức năng |
|-----|-----------|
| `fetchOpenDeThis()` | GET `/api/DeThi/open`; cập nhật `_openDeThis` |
| `fetchAdminDeThis(page, pageSize)` | GET `/api/DeThi` (admin); cập nhật `_adminDeThis` |
| `createDeThi(...)` | POST `/api/DeThi`; nếu trạng thái là mở (`isOpen`) thì append vào `_openDeThis` |
| `updateDeThi(...)` | PUT `/api/DeThi/{id}`; cập nhật `_openDeThis` (nếu đề thi đang mở) |
| `deleteDeThi(id)` | DELETE `/api/DeThi/{id}`; xóa khỏi `_openDeThis` và `_adminDeThis.items`, giảm `total` |

Provider không tự động refresh `adminDeThis` sau CRUD (UI chủ động gọi `fetchAdminDeThis`).

## 5. Service `DeThiService`

- `fetchDeThis`: GET `/api/DeThi` với query `page`, `pageSize`. Trả `PaginatedResponse<DeThi>`.
- `fetchOpenDeThis`: GET `/api/DeThi/open` (không phân trang) → danh sách dành cho người dùng.
- `createDeThi`/`updateDeThi`: gửi JSON chứa `tenDeThi`, `chuDeId`, `soCauHoi`, `thoiGianThi`, `trangThai`, `allowMultipleAttempts`.
- `deleteDeThi`: DELETE `/api/DeThi/{id}`.
- Service kiểm tra response phải là `Map<String,dynamic>` (hoặc `List` đối với open); nếu không → throw `ApiException` với thông báo thân thiện.

## 6. Backend `DeThiController`

- `[Authorize]` toàn controller; endpoint admin thêm `[Authorize(Roles="Admin")]`.
- **GET `/api/DeThi`** (Admin):
  - Validate `page ≥ 1`, `pageSize ∈ [1,100]`.
  - Include `ChuDe`, order theo `NgayTao` giảm dần.
  - Trả `{ total, items }` với dữ liệu tối giản (Id, TenDeThi, ChuDeId, TrangThai, SoCauHoi, ThoiGianThi, NgayTao, AllowMultipleAttempts, ChuDe{...}}`).
- **GET `/api/DeThi/{id}`**: trả đầy đủ entity kèm chủ đề.
- **GET `/api/DeThi/open`** (AllowAnonymous): lọc theo `TrangThai` nằm trong `mo/mở/open` (case-insensitive), trả danh sách để client hiển thị.
- **POST `/api/DeThi`** (Admin): tạo mới từ entity `DeThi`; không có validation riêng, tin tưởng client.
- **PUT `/api/DeThi/{id}`** (Admin): yêu cầu `id == deThi.Id`; update toàn bộ trường.
- **DELETE `/api/DeThi/{id}`** (Admin): nếu có `KetQuaThi` liên quan → `400 BadRequest "Không thể xóa đề thi vì có kết quả thi liên quan."`; ngược lại xoá khỏi DB.

## 7. Trạng thái, trường dữ liệu quan trọng

| Trường | Mô tả |
|--------|-------|
| `TrangThai` | Chuỗi "Mo" / "Dong" (case-sens). UI hiển thị badge và filter. |
| `SoCauHoi` | Số câu hỏi cần khi tạo/thi. Không kiểm tra với số câu thực tế; cần đảm bảo thủ công. |
| `ThoiGianThi` | Đơn vị phút. |
| `AllowMultipleAttempts` | Bool cho phép thí sinh thi nhiều lần. Ảnh hưởng tại luồng backend `ThiController` (không nằm trong file này). |
| `NgayTao` | Được dùng để sắp xếp (giảm dần) và hiển thị card. |

## 8. Xử lý lỗi & lưu ý UX

- Khi backend trả lỗi (ví dụ xoá đề thi có kết quả thi) → `DeThiProvider.deleteDeThi` set `_error`, snackbar hiển thị "Không thể xoá đề thi vì đang được sử dụng.".
- Form không kiểm tra `soCauHoi > 0` hay `thoiGianThi > 0`; nên bổ sung validator nếu cần.
- Sau khi tạo đề thi trạng thái mở, UI thi của học sinh sẽ thấy ngay vì `createDeThi` thêm vào `_openDeThis`.
- Không có kiểm tra trùng tên đề thi → cân nhắc bổ sung ở backend nếu yêu cầu business.
- Bộ lọc đang hoạt động trên client; khi `total` lớn, nên cân nhắc filter server-side (truyền `keyword`, `topicId`, `status`).

## 9. Kiểm thử đề xuất

| Kiểm thử | Công cụ | Mục tiêu |
|----------|---------|----------|
| Unit test `DeThiProvider` | `flutter_test` với mock `DeThiService` | Đảm bảo create/update/delete cập nhật `_openDeThis`, `_adminDeThis`, `_error` đúng; phân trang không bị sai. |
| Widget test tab đề thi | Pump `AdminDashboardScreen` với provider giả | Kiểm tra search/filter, phân trang, dialog validation, snackbar khi xoá thất bại. |
| API integration test | ASP.NET `WebApplicationFactory` | Validate phân quyền Admin, kiểm tra Delete chặn khi có `KetQuaThi`, confirm `/open` trả đúng dữ liệu theo trạng thái. |
| Manual QA | Thiết bị thật + admin | Tạo/sửa đề thi, đổi trạng thái, bật/tắt `allowMultipleAttempts`, xoá đề thi có và không có kết quả thi. |

## 10. Ghi chú mở rộng

- Nên đồng bộ kiểm tra số câu hỏi (so với số câu thực tế trong chủ đề) ở cả client và server để tránh đề thi thiếu câu.
- Có thể bổ sung trường mô tả hoặc điều kiện truy cập cho đề thi trong tương lai.
- Khi số lượng đề thi tăng lớn, cân nhắc thêm phân trang server-side nâng cao (keyword/status/topic) để giảm lọc client.
- `AllowMultipleAttempts` hiện mặc định `true` khi mở dialog; xem xét đặt mặc định `false` nếu chính sách yêu cầu chỉ thi 1 lần.
- Nếu cần audit, ghi log mọi thao tác CRUD đề thi kèm admin thực hiện.
