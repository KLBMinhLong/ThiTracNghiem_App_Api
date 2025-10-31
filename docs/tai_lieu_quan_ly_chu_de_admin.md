# 🗂️ QUẢN LÝ CHỦ ĐỀ (ADMIN) - TÀI LIỆU CHI TIẾT

## 1. Luồng tổng quan

```
Admin biểu tượng trong HomeScreen xuất hiện khi AuthProvider.isAdmin == true
  → Nhấn chuyển sang AdminDashboardScreen
  → initState() gọi _loadInitialData()
      ↳ ChuDeProvider.fetchChuDes(page = 1, pageSize = 50)
      ↳ Tải dữ liệu cho các tab khác (Users, Questions, Exams, Contacts)
  → Tab "Chủ đề" hiển thị danh sách tại _buildTopicsSection()
      ↳ TextField lọc nội bộ theo tên/mô tả (không gọi API)
      ↳ Nút "Thêm chủ đề" → _showTopicDialog()
      ↳ Chạm vào card hoặc menu "Chỉnh sửa" → _showTopicDialog(topic)
      ↳ Menu "Xoá" → _deleteTopic(id)
      ↳ Sau thao tác create/update/delete: fetchChuDes() để đồng bộ danh sách & các tab liên quan
  → ChuDeProvider.notifyListeners() → Question tab, Exam tab, import Excel... nhận chủ đề mới
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File |
|------------|---------|------|
| Tab "Chủ đề" trong admin | UI danh sách, tìm kiếm, popup menu | `thitracnghiemapp/lib/screens/admin/admin_dashboard_screen.dart` (_buildTopicsSection) |
| Dialog tạo/cập nhật chủ đề | Thu nhập dữ liệu, trả `_TopicDialogResult` | `admin_dashboard_screen.dart` (`_showTopicDialog`) |
| Hộp thoại xác nhận xoá | Gọi provider.deleteChuDe | `admin_dashboard_screen.dart` (`_deleteTopic`) |
| Provider quản lý chủ đề | Lưu danh sách, gọi service CRUD | `thitracnghiemapp/lib/providers/chu_de_provider.dart` |
| Service REST | `GET/POST/PUT/DELETE /api/ChuDe` | `thitracnghiemapp/lib/services/chu_de_service.dart` |
| Model Flutter | Parse JSON → `ChuDe` | `thitracnghiemapp/lib/models/chu_de.dart` |
| Controller backend | Triển khai API, phân quyền | `ThiTracNghiemApi/Controllers/ChuDeController.cs` |
| Entity EF Core | Bảng `ChuDes` | `ThiTracNghiemApi/Models/ChuDe.cs` |

> Số dòng tham chiếu dựa trên nhánh `main` ngày 31/10/2025.

## 3. Giao diện & hành vi tab "Chủ đề"

- **Thanh tìm kiếm**: TextField với `_topicSearchController`; nhập ký tự lập tức lọc (`setState`) dựa trên `tenChuDe` và `moTa` (so sánh lowercase). Không gọi lại API.
- **Nút hành động**:
  - `Thêm chủ đề` dùng `_buildActionButton` (gradient primary). Nhấn → `_showTopicDialog()` với `topic = null`.
  - Xoá biểu tượng tìm kiếm khi có text → reset bộ lọc.
- **Danh sách chủ đề**:
  - `filteredTopics` là danh sách đã lọc. Render qua `ListView.builder` trong `Expanded`.
  - Mỗi card hiển thị icon folder, tên chủ đề (font 14sp, bold) và mô tả (nếu có, tối đa 2 dòng).
  - Toàn bộ card có `InkWell` → nhấn mở dialog chỉnh sửa.
- **Menu ngữ cảnh** (`PopupMenuButton`):
  - `Chỉnh sửa`: gọi `_showTopicDialog(topic: topic)`.
  - `Xoá`: gọi `_deleteTopic(topic.id)`.
- **Trạng thái rỗng**: nếu không có chủ đề (sau khi lọc hoặc danh sách rỗng) hiển thị card gradient + thông báo "Không có chủ đề".

### Dialog tạo/cập nhật (`_showTopicDialog`)
- Form gồm 2 trường: `Tên chủ đề` (bắt buộc, validate không rỗng) và `Mô tả` (tuỳ chọn).
- Khi nhấn `Lưu`, dialog trả `_TopicDialogResult` chứa `tenChuDe`, `moTa`, `id` (nếu cập nhật).
- Provider được gọi **sau** khi dialog đóng nhằm tránh xung đột rebuild.
- Sau khi create/update thành công:
  - Gọi `provider.fetchChuDes()` để đồng bộ dữ liệu (giúp các tab khác cập nhật).
  - Snackbar báo "Đã thêm chủ đề mới" hoặc "Đã cập nhật chủ đề".
- Trường hợp lỗi (API trả lỗi hoặc exception): Snackbar hiển thị `provider.error` hoặc thông báo fallback.

### XOÁ chủ đề (`_deleteTopic`)
- Hiển thị AlertDialog xác nhận.
- Nếu đồng ý: `provider.deleteChuDe(id)`. Thành công → fetchChuDes() & snackbar "Đã xoá chủ đề".
- Nếu backend trả lỗi (ví dụ đang có đề thi/câu hỏi liên quan) → snackbar hiển thị `provider.error` (mặc định "Không thể xoá chủ đề vì đang được sử dụng.").

## 4. `ChuDeProvider`

| Hàm | Chức năng | Ghi chú |
|-----|-----------|---------|
| `fetchChuDes({page=1,pageSize=50})` | Gọi service, cập nhật `_chuDes` và `_paged` | Đặt `_loading=true`, `_error=null`, `notifyListeners()` trước/sau.
| `createChuDe` | POST API, thêm chủ đề vào danh sách cục bộ | Push vào cuối danh sách; trả `ChuDe?` để UI quyết định hiển thị thông báo.
| `updateChuDe` | PUT API, cập nhật item trong `_chuDes` | Dùng `map` thay thế, trả bool cho biết thành công.
| `deleteChuDe` | DELETE API, loại khỏi danh sách | Trả bool; `_error` giữ thông báo.

Provider không tự phân trang nâng cao; `_paged` lưu meta nếu cần hiển thị sau này.

## 5. `ChuDeService`

- **GET `/api/ChuDe`**: nhận `page`, `pageSize` → trả `PaginatedResponse<ChuDe>`.
- **GET `/api/ChuDe/{id}`**: dùng khi cần chi tiết (không dùng trong UI admin hiện tại nhưng provider hỗ trợ).
- **POST `/api/ChuDe`**: body `{ tenChuDe, moTa }`.
- **PUT `/api/ChuDe/{id}`**: body `{ id, tenChuDe, moTa }`.
- **DELETE `/api/ChuDe/{id}`**: không trả dữ liệu; nếu lỗi, `ApiException` ném lên provider.
- Service luôn xác nhận response dạng `Map<String,dynamic>`; nếu không, ném `ApiException` với thông báo thân thiện ("Không lấy được danh sách chủ đề", "Không thể tạo chủ đề", ...).

## 6. Backend `ChuDeController`

- `[Authorize]` toàn bộ controller, riêng GET danh sách `AllowAnonymous` (client học sinh cần xem chủ đề).
- **GET `/api/ChuDe`**:
  - Chuẩn hoá `page >= 1`, `pageSize ∈ [1,100]`.
  - Sắp xếp theo `TenChuDe` tăng dần.
  - Trả `{ total, items: [{Id, TenChuDe, MoTa}] }`.
- **GET `/api/ChuDe/{id}`**: trả 404 nếu không tồn tại.
- **POST `/api/ChuDe`** (Admin-only):
  - Body là entity `ChuDe`; `TenChuDe` `[Required]`.
  - Lưu DB, trả `201 Created` cùng dữ liệu mới.
- **PUT `/api/ChuDe/{id}`** (Admin-only):
  - Kiểm tra `id == chuDe.Id`, nếu không `400 BadRequest`.
  - `Entry.State = Modified` rồi `SaveChangesAsync()` --> trả `204 NoContent`.
- **DELETE `/api/ChuDe/{id}`** (Admin-only):
  - Trả `404` nếu không tìm thấy.
  - Nếu tồn tại `DeThi` hoặc `CauHoi` liên quan (`AnyAsync`) → `400 BadRequest` kèm thông báo "Không thể xóa chủ đề vì có đề thi hoặc câu hỏi liên quan.".
  - Nếu không, xoá khỏi `ChuDes` và `SaveChangesAsync()`.

## 7. Tích hợp với tab khác

- Tab "Câu hỏi" và "Đề thi" sử dụng `ChuDeProvider.chuDes` để hiển thị dropdown lọc/chọn chủ đề. Sau mỗi lần CRUD, `_showTopicDialog` gọi `provider.fetchChuDes()` giúp những tab này tự động thấy dữ liệu mới.
- Import Excel câu hỏi (`_importQuestions`) yêu cầu `_selectedTopicForImport` luôn nằm trong danh sách chủ đề hiện tại. Logic `addPostFrameCallback` đảm bảo khi danh sách thay đổi sẽ chọn topic đầu tiên.

## 8. Xử lý lỗi & UX cần lưu ý

- Khi backend trả `BadRequest` (ví dụ xoá chủ đề đang sử dụng) → Provider đặt `_error`, UI hiển thị snackbar với thông báo rõ.
- `createChuDe`/`updateChuDe` nếu backend trả lỗi (ví dụ trống `tenChuDe`) → Provider ghi `_error = error.toString()`; nên xem xét chuẩn hoá thông báo ở backend nếu cần đa ngôn ngữ.
- `fetchChuDes` chỉ lấy 50 bản ghi; nếu số chủ đề lớn hơn, cần nâng `pageSize` hoặc bổ sung phân trang UI.
- Form không kiểm tra trùng tên. Nếu muốn enforce, cần thêm logic backend (unique constraint) và xử lý thông báo tại UI.

## 9. Kiểm thử đề xuất

| Kiểm thử | Công cụ | Mục tiêu |
|----------|---------|----------|
| Unit test `ChuDeProvider` | `flutter_test` với mock `ChuDeService` | Đảm bảo create/update/delete cập nhật `_chuDes`, `_error`, notifyListeners đúng cách.
| Widget test tab "Chủ đề" | Pump `AdminDashboardScreen` với provider giả | Kiểm tra lọc, mở dialog, popup menu và snackbar phản hồi.
| API integration test | `WebApplicationFactory` (ASP.NET) | Xác nhận phân quyền Admin, validate `page/pageSize`, cấm xoá khi có `DeThi/CauHoi`.
| Manual QA | Thiết bị thật + tài khoản admin | Tạo mới → kiểm tra dropdown ở tab câu hỏi, xoá chủ đề chưa sử dụng, thử xoá chủ đề đã gán đề thi để thấy cảnh báo.

## 10. Ghi chú mở rộng

- Nếu muốn thêm trường phân loại (ví dụ màu sắc, biểu tượng), mở rộng entity `ChuDe` và điều chỉnh dialog tương ứng.
- Nên cân nhắc cập nhật câu hỏi/đề thi khi đổi tên chủ đề (hiện tại chỉ lưu `ChuDeId`, nên đổi tên không ảnh hưởng).
- Khi số lượng chủ đề tăng cao, chuyển sang bảng dữ liệu (DataTable) và hỗ trợ phân trang/ sắp xếp phía server để tối ưu hiệu năng.
- Để hỗ trợ lọc nâng cao cho tab câu hỏi/đề thi, có thể bổ sung API `GET /api/ChuDe?keyword=` thay vì lọc client-side.
