# ❓ QUẢN LÝ CÂU HỎI (ADMIN) - TÀI LIỆU CHI TIẾT

## 1. Luồng tổng quan

```
HomeScreen (icon Admin chỉ hiển thị nếu AuthProvider.isAdmin)
  → Nhấn → AdminDashboardScreen
  → initState() → _loadInitialData()
      ↳ CauHoiProvider.refreshCauHois() (Trang 1, pageSize = 20)
      ↳ ChuDeProvider.fetchChuDes() (phục vụ dropdown)
      ↳ Các provider khác (Users/Exams/Contacts)
  → Tab "Câu hỏi" (_buildQuestionsSection)
      ↳ Hàng action: nút Lọc, nút "Thêm câu hỏi"
      ↳ Bộ lọc chủ đề + chọn chủ đề import Excel
      ↳ Nút "Import Excel" → _importQuestions()
      ↳ ListView câu hỏi (có Pull-to-Refresh, Load more)
      ↳ Popup menu từng câu hỏi: Chỉnh sửa/Xoá
      ↳ Dialog thêm/chỉnh sửa `_showQuestionDialog`
      ↳ Xoá kiểm tra phụ thuộc đề thi `_deleteQuestion`
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File |
|------------|---------|------|
| UI tab câu hỏi | Render danh sách, filter, import, dialog | `thitracnghiemapp/lib/screens/admin/admin_dashboard_screen.dart` (`_buildQuestionsSection`, `_showQuestionDialog`, `_deleteQuestion`, `_importQuestions`) |
| Provider câu hỏi | Trạng thái danh sách, CRUD, import | `thitracnghiemapp/lib/providers/cau_hoi_provider.dart` |
| Service REST câu hỏi | Gọi API `/api/CauHoi` | `thitracnghiemapp/lib/services/cau_hoi_service.dart` |
| Model Flutter | `CauHoi`, quan hệ `ChuDe` | `thitracnghiemapp/lib/models/cau_hoi.dart` |
| Backend controller | CRUD + import Excel, phân quyền | `ThiTracNghiemApi/Controllers/CauHoiController.cs` |
| DTO import backend | Nhận `IFormFile` + `TopicId` | `ThiTracNghiemApi/Dtos/CauHoi/ImportCauHoisRequest.cs` |
| Entity EF Core | `CauHoi` + liên kết `ChuDe` | `ThiTracNghiemApi/Models/CauHoi.cs` |
| Đề thi liên quan | Kiểm tra số câu hỏi trước khi xoá | `thitracnghiemapp/lib/providers/de_thi_provider.dart`, `admin_dashboard_screen.dart` |

> Tham chiếu commit ngày 31/10/2025.

## 3. Giao diện & hành vi tab "Câu hỏi"

### 3.1 Hàng hành động & bộ lọc
- **Nút "Lọc"**: mở/đóng khu vực filter.
- **Filter chủ đề**: Dropdown liệt kê `ChuDeProvider.chuDes`. Khi chọn → `CauHoiProvider.setTopicFilter(topicId)` → load lại danh sách.
- **Chủ đề Excel**: Dropdown riêng để chọn chủ đề áp dụng cho import. Giá trị mặc định là chủ đề đầu tiên, tự động cập nhật nếu danh sách đổi.
- **Nút "Import Excel"**: disable nếu đang import hoặc không có chủ đề. Gọi `_importQuestions()` (FilePicker `.xlsx`).
- **Nút "Thêm câu hỏi"**: mở `_showQuestionDialog()` ở chế độ tạo.

### 3.2 Danh sách câu hỏi
- `RefreshIndicator` cho phép kéo xuống gọi `questionProvider.refreshCauHois(topicId: selectedTopicId)`.
- Mỗi item hiển thị:
  - Icon (gradient)
  - Nội dung câu hỏi (bold)
  - Tag chủ đề (badge màu nhạt)
  - Nhãn đáp án đúng (`AnswerChip` hiển thị A/B/C/D)
  - Popup menu `⋮` với hành động "Chỉnh sửa"/"Xoá".
- Cuối danh sách, nếu `questionProvider.canLoadMore == true`, hiển thị card "Tải thêm câu hỏi" hoặc spinner khi `_loadingMore`.
- `questionProvider.error` (khi load) render banner đỏ ở đầu danh sách.

### 3.3 Dialog thêm/chỉnh sửa (`_showQuestionDialog`)
- Form input gồm: Dropdown chủ đề, Nội dung, Đáp án A/B (bắt buộc), Đáp án C/D (tuỳ chọn), Đáp án đúng (text A/B/C/D).
- Khi xác nhận, dialog trả `_QuestionDialogResult` với toàn bộ dữ liệu, sau đó:
  - Nếu `isUpdate`: gọi `questionProvider.updateCauHoi(...)`.
  - Nếu tạo mới: `questionProvider.createCauHoi(...)`.
  - Sau thao tác thành công → `questionProvider.refreshCauHois(topicId: selectedTopicId)` rồi snackbar thông báo.
- Hình ảnh/âm thanh chưa được hỗ trợ trong UI (provider & service có tham số nhưng hiện không dùng).

### 3.4 Xoá câu hỏi (`_deleteQuestion`)
- Tìm câu hỏi hiện tại từ provider. Nếu không có, snackbar báo lỗi.
- Trước khi gọi API, đếm số câu hỏi còn lại của chủ đề đó. So sánh với tất cả đề thi đã tải (adminDeThis + openDeThis).
- Nếu có đề `DeThi` yêu cầu nhiều câu hơn số còn lại sau khi xoá → từ chối, snackbar giải thích với tên đề thi và số lượng yêu cầu.
- Nếu không bị chặn → `questionProvider.deleteCauHoi(id)` → snackbar thành công/thất bại.

### 3.5 Import Excel (`_importQuestions`)
- Mở FilePicker, chấp nhận `.xlsx`.
- Nếu chưa chọn chủ đề → snackbar nhắc.
- Upload qua `CauHoiProvider.importCauHois(File, topicId)`.
- Thành công: snackbar với thông điệp backend (ví dụ "Import thành công 20 câu hỏi."). Sau import, provider tự refresh theo filter hiện tại.

## 4. Provider `CauHoiProvider`

| Thuộc tính | Ý nghĩa |
|------------|---------|
| `_cauHois` | Danh sách câu hỏi hiện render (đã áp dụng filter & phân trang) |
| `_selectedTopicId` | Filter chủ đề hiện hành (null = tất cả) |
| `_nextPage` | Trang tiếp theo khi load more |
| `_hasMore` | Còn dữ liệu ở server hay không |
| `_loading`, `_loadingMore` | Trạng thái hiển thị spinner/Load more |
| `_error` | Thông báo lỗi khi request fail |

| Hàm | Chức năng |
|-----|-----------|
| `refreshCauHois({topicId})` | Reset trang về 1, tải lại dữ liệu. Nếu lỗi → `_cauHois = []`. |
| `loadMoreCauHois()` | Nối thêm trang mới nếu `canLoadMore` |
| `setTopicFilter(topicId)` | Cập nhật filter (có thể null) và gọi refresh |
| `createCauHoi(...)` | POST; nếu filter đang xem phù hợp, prepend câu hỏi mới vào `_cauHois` |
| `updateCauHoi(...)` | PUT; thay thế item trong danh sách |
| `deleteCauHoi(id)` | DELETE; xoá item khỏi `_cauHois` |
| `importCauHois(file, topicId)` | Multipart upload; refresh sau khi import |

Provider luôn `notifyListeners()` để UI cập nhật, đồng thời trả về giá trị (bool/`CauHoi?`) cho UI hiển thị snackbar thích hợp.

## 5. Service `CauHoiService`

- `fetchCauHois`: GET `/api/CauHoi?page=N&pageSize=M&topicId=...`; trả `PaginatedResponse<CauHoi>` (server trả kèm `page`, `pageSize`, `total`).
- `createCauHoi`, `updateCauHoi`, `deleteCauHoi`: tương ứng POST/PUT/DELETE. Payload gồm nội dung và đáp án, `chuDeId` bắt buộc.
- `importFromExcel`: Multipart POST `/api/CauHoi/import` với field `topicId` và file `file`. Sử dụng token từ `ApiClient`; nếu thiếu → throw `ApiException`.
- Với response lỗi, service cố gắng parse JSON để lấy message thân thiện.

## 6. Backend `CauHoiController`

- `[Authorize]` toàn bộ controller; thao tác viết (POST/PUT/DELETE/IMPORT) yêu cầu role `Admin`.
- **GET `/api/CauHoi`**:
  - Validate `page >= 1`, `1 <= pageSize <= 200`.
  - Include `ChuDe` để client hiển thị tên chủ đề.
  - Sắp xếp `Id` giảm dần.
  - Filter theo `topicId` nếu cung cấp.
  - Trả `{ total, page, pageSize, items }`.
- **GET `/api/CauHoi/{id}`**: trả câu hỏi kèm `ChuDe`.
- **POST `/api/CauHoi`**: tạo câu hỏi mới từ body `CauHoi`. Không có validation custom (tin tưởng client).
- **PUT `/api/CauHoi/{id}`**: yêu cầu `id == cauHoi.Id`, update full entity.
- **DELETE `/api/CauHoi/{id}`**: xoá trực tiếp; không kiểm tra đề thi (logic kiểm tra đặt ở client `_deleteQuestion`).
- **POST `/api/CauHoi/import`**:
  - Yêu cầu file `.xlsx` và `TopicId` hợp lệ.
  - Dùng ClosedXML đọc sheet 1, bỏ header, duyệt từng hàng.
  - Bỏ qua dòng thiếu dữ liệu bắt buộc; collect lỗi vào danh sách `errors`.
  - Nếu import 0 câu → `BadRequest` với lỗi.
  - Thành công: trả JSON `{ message, imported, skipped }`.

## 7. Định dạng import Excel (mặc định)

| Cột | Nội dung | Bắt buộc |
|-----|----------|----------|
| 1 | Nội dung câu hỏi | ✅ |
| 2 | Đáp án A | ✅ |
| 3 | Đáp án B | ✅ |
| 4 | Đáp án C | ❌ (bỏ trống nếu không dùng) |
| 5 | Đáp án D | ❌ |
| 6 | Đáp án đúng (A/B/C/D) | ✅ |

Hàng đầu tiên được xem là header và bị bỏ qua. Những dòng thiếu A/B hoặc đáp án đúng sẽ bị ghi vào danh sách lỗi và bỏ qua.

## 8. Xử lý lỗi & UX cần lưu ý

- `questionProvider.error` được hiển thị ở đầu tab khi load thất bại.
- Sau khi import, provider tự refresh; nếu danh sách đang lọc theo chủ đề khác, kết quả import có thể không thấy ngay.
- `_deleteQuestion` chặn xoá khi đề thi yêu cầu nhiều câu hơn số còn lại. Backend hiện không kiểm tra, nên nếu client bỏ qua logic này sẽ có nguy cơ đề thi thiếu câu.
- `CauHoiProvider.createCauHoi` thêm câu hỏi mới vào đầu danh sách nhưng không cập nhật `total` hay `_hasMore`; sau `refreshCauHois` sẽ đồng bộ lại.
- `loadMoreCauHois` không debounce; cần tránh click nhiều lần khi `_loadingMore` đang true.

## 9. Kiểm thử đề xuất

| Kiểm thử | Công cụ | Mục tiêu |
|----------|---------|----------|
| Unit test `CauHoiProvider` | `flutter_test` với mock `CauHoiService` | Đảm bảo refresh/reset trạng thái, load more nối dữ liệu, create/update/delete xử lý danh sách & `_error` đúng.
| Widget test tab câu hỏi | Pump `AdminDashboardScreen` với provider giả | Kiểm tra filter, load more, import button state, dialog validation, snackbar khi xoá bị chặn.
| API integration test | ASP.NET `WebApplicationFactory` | Xác minh phân quyền Admin, validate tham số page/pageSize, import Excel (thành công & lỗi), delete/update.
| Manual QA | Thiết bị thật + tài khoản admin | Tạo câu hỏi mới, import file mẫu, filter theo chủ đề, thử xoá câu hỏi đang dùng trong đề thi để thấy cảnh báo.

## 10. Ghi chú mở rộng

- Cân nhắc bổ sung validation backend (ví dụ kiểm tra `DapAnDung` nằm trong [A-D], bắt buộc `DapAnA/B`).
- Hiện UI chưa hỗ trợ upload file hình ảnh/âm thanh dù service có tham số → cần mở rộng khi triển khai đa phương tiện.
- Nếu số lượng câu hỏi lớn, nên bổ sung tìm kiếm theo từ khoá và phân trang server-side (đã có) kèm filter nhiều tiêu chí.
- Nên đồng bộ logic chặn xoá câu hỏi lên backend để đảm bảo an toàn dữ liệu khi dùng API ngoài ứng dụng.
- Import Excel hiện chỉ nhận `.xlsx`. Nếu cần hỗ trợ `.xls`, backend cần mở rộng kiểm tra `Path.GetExtension`.
