# LUỒNG THI: DANH SÁCH ĐỀ → CHI TIẾT ĐỀ → KHỞI TẠO BÀI THI

## 1. Tóm tắt luồng

```
HomeScreen._loadInitialData()
  → DeThiProvider.fetchOpenDeThis()
  → DeThiService.fetchOpenDeThis()
  → GET /api/DeThi/open (DeThiController.GetOpenDeThis)
  → DeThiProvider.openDeThis được cập nhật
  → ChuDeProvider.fetchChuDes() tải dropdown chủ đề

Người dùng tìm kiếm/lọc trong _ExamTab
  → Consumer2<DeThiProvider, ChuDeProvider> render danh sách
  → RefreshIndicator gọi lại fetchOpenDeThis()

Chọn một đề thi trong danh sách
  → Navigator.push(ExamDetailScreen)

ExamDetailScreen.initState
  → DeThiProvider.fetchOpenDeThis() (làm mới trạng thái)
  → Đồng bộ thông tin đề và trạng thái mở

Nhấn "Bắt đầu làm bài"
  → ExamDetailScreen._startQuiz()
      → ThiProvider.reset()
      → ThiProvider.startThi(deThiId)
      → ThiService.startThi(deThiId)
      → POST /api/Thi/start/{deThiId} (ThiController.StartThi)
      → Nhận StartThiResponse (KetQuaThiId + danh sách câu hỏi)
      → Navigator.push(QuizScreen)
```

> Lưu ý: Quy trình bình luận trên màn hình chi tiết đề đã được tách sang `docs/huong_dan_tinh_nang_binh_luan.md`.

## 2. Thành phần tham gia & vị trí mã nguồn

| Bước | Mô tả | File liên quan |
|------|-------|----------------|
| Load dữ liệu ban đầu | Khởi động các provider (đề thi mở, chủ đề, lịch sử, liên hệ) | `lib/screens/home_screen.dart` (`HomeScreen._loadInitialData`) |
| Danh sách đề + tìm kiếm | UI tab thi, bộ lọc, empty/loading state | `lib/screens/home_screen.dart` (`_ExamTab`) |
| Provider đề thi | Giữ danh sách đề mở, loading, lỗi | `lib/providers/de_thi_provider.dart` |
| Service đề thi | Giao tiếp API `/api/DeThi` | `lib/services/de_thi_service.dart` |
| API danh sách đề | Truy vấn EF Core, lọc trạng thái mở | `ThiTracNghiemApi/Controllers/DeThiController.cs` |
| Màn chi tiết đề | Hiển thị thông tin đề và nút bắt đầu làm bài | `lib/screens/exam_detail_screen.dart` |
| Provider thi | Khởi tạo session, lưu kết quả nộp bài | `lib/providers/thi_provider.dart` |
| Service thi | `/api/Thi/start|update|submit` | `lib/services/thi_service.dart` |
| API thi | Tạo KetQuaThi, chọn câu hỏi, chấm điểm | `ThiTracNghiemApi/Controllers/ThiController.cs` |
| Màn làm bài | Tiếp nhận session, đồng bộ timer, điều hướng kết quả | `lib/screens/quiz_screen.dart` |
| Model đề thi | Parse JSON → Dart, `isOpen` helper | `lib/models/de_thi.dart` |
| Model quiz session | Câu hỏi, đáp án đã chọn, copy helpers | `lib/models/quiz_session.dart` |

> Số dòng tham chiếu dựa trên commit hiện tại (31/10/2025). Nếu thay đổi, tìm theo tên hàm tương ứng.

## 3. Chi tiết giao diện Flutter

### 3.1 `HomeScreen` và `_ExamTab`

- `HomeScreen.initState` đăng ký listener với `_searchController` để gọi `setState`, giúp kết quả lọc cập nhật ngay khi người dùng gõ.
- `_loadInitialData()` chạy sau frame đầu tiên và sử dụng `Future.wait` để tải đồng thời đề thi, chủ đề, lịch sử và danh sách góp ý của người dùng. Trạng thái `_initializing` điều khiển skeleton loading cho toàn bộ tab.
- `_ExamTab` bọc nội dung trong `Consumer2<DeThiProvider, ChuDeProvider>` để lắng nghe thay đổi từ cả hai nguồn dữ liệu (danh sách đề + danh sách chủ đề).
- Thanh tìm kiếm đọc `searchController.text` và lọc client-side theo `tenDeThi` hoặc `chuDe.tenChuDe`. Nút clear đặt `searchController.clear()`, trigger rebuild.
- Dropdown chủ đề hiển thị `Tất cả chủ đề` + danh sách từ `ChuDeProvider.chuDes`. Khi thay đổi sẽ gọi callback `onTopicSelected` để cập nhật state ở `HomeScreen`.
- `RefreshIndicator` gọi `deThiProvider.fetchOpenDeThis()` để đồng bộ dữ liệu với backend khi người dùng kéo xuống.
- Kết quả hiển thị `Card` với icon gradient, thông tin chủ đề, thời lượng, số câu hỏi. Hàm `topicNameFor` đảm bảo fallback nếu API chưa hydrate chủ đề.
- Khi danh sách trống, `_ExamTab` dùng `EmptyStateWidget` với thông báo tùy theo trạng thái lọc.
- Tapping một `Card` sẽ gọi `onOpenExam`, `Navigator.push` mở `ExamDetailScreen` và truyền `DeThi` đã chọn.

### 3.2 `ExamDetailScreen`

- `initState` chạy `Future.wait` với `DeThiProvider.fetchOpenDeThis()` để đồng bộ trạng thái đề với danh sách bên ngoài. Nếu provider báo lỗi, `UIHelpers.showErrorSnackBar` sẽ hiển thị thông báo.
- Phần thông tin đề nằm trong `Card` với lưới `_InfoCard`: chủ đề, thời gian, số câu, ngày tạo. Hàm `topicName()` tra cứu `ChuDeProvider.chuDes` nếu `DeThi.chuDe` rỗng.
- Nút `FilledButton` start bị disable nếu `deThi.isOpen` false hoặc đang `_startingQuiz`. Khi bấm:
  1. `ThiProvider.reset()` để xóa session cũ.
  2. Await `thiProvider.startThi(deThi.id)`.
  3. Kiểm tra lỗi: nếu message chứa `SqlException`, chuyển thành thông báo thân thiện.
  4. Điều hướng tới `QuizScreen` khi thành công.

> Chi tiết trải nghiệm bình luận trên màn hình này được mô tả trong `docs/huong_dan_tinh_nang_binh_luan.md`.

### 3.3 `QuizScreen`

- Được push ngay sau khi `ThiProvider.startThi` trả session. `QuizScreen.initState` vẫn kiểm tra nếu `currentSession` chưa có (ví dụ mở từ deep link) thì gọi lại `startThi` để đảm bảo đồng bộ.
- Khi nhận được session, `_startTimer` khởi tạo `Timer.periodic` dựa trên `thoiGianThi` (phút → giây). Timer tự động gọi `_submit` khi hết thời gian.
- UI hiển thị header tiến độ, thân câu hỏi (`_QuestionBody`), nút điều hướng, và `WillPopScope` bắt sự kiện back để xác nhận trước khi rời bài thi.
- `dispose` hủy timer và `ThiProvider.reset()` nhằm tránh rò rỉ session khi người dùng thoát giữa chừng.

## 4. Provider và Service

### 4.1 `DeThiProvider`

- Thuộc tính chính: `_openDeThis`, `_loadingOpen`, `_error`.
- `fetchOpenDeThis()` đặt `_loadingOpen = true`, reset `_error`, gọi `DeThiService.fetchOpenDeThis()`. Bắt mọi exception và lưu `error.toString()` để UI đọc.
- Sau khi cập nhật `_openDeThis`, provider `notifyListeners()` khiến `_ExamTab` render lại.
- Hành động CRUD khác (`create`, `update`, `delete`) đảm bảo giữ danh sách mở đồng bộ sau thao tác admin.

### 4.2 `ThiProvider`

- Quản lý `_currentSession`, `_submitResult`, `_isLoading`, `_error`.
- `startThi(deThiId)` đặt `_isLoading = true`, reset trạng thái trước khi gọi `ThiService.startThi`. Nếu `ApiException`, lưu message thân thiện.
- `updateDapAn` gọi `ThiService.updateDapAn` và cập nhật `QuizSession` cục bộ bằng `copyWithUpdatedAnswer` để UI phản ánh ngay.
- `submitThi` gọi API `POST /api/Thi/submit/{ketQuaThiId}` và giữ `SubmitThiResult` cho `ResultScreen`.
- `reset()` đưa provider về trạng thái rỗng. Được gọi trước khi bắt đầu bài mới và khi thoát giữa chừng.

### 4.3 `ChuDeProvider`

- `fetchChuDes` dùng `ChuDeService.fetchChuDes` để lấy danh sách dropdown. Loading + error pattern giống provider khác.
- Được `ExamDetailScreen` sử dụng để hiển thị tên chủ đề khi `DeThi.chuDe` chưa hydrate.

## 5. Backend API liên quan

### 5.1 `DeThiController`

- `GET /api/DeThi/open` (AllowAnonymous) lọc các đề có trạng thái "mo"/"mở"/"open", trả về danh sách có `ChuDe` embed.
- `GET /api/DeThi/{id}` trả về chi tiết đề (cần auth). `ExamDetailScreen` hiện tại nhận `DeThi` từ danh sách nên không gọi trực tiếp, nhưng provider có thể dùng khi cần sync.
- `GET /api/DeThi` (Admin) phục vụ dashboard quản trị.

### 5.2 `ThiController`

- `POST /api/Thi/start/{deThiId}`:
  - Lấy user ID qua `User.ResolveUserIdAsync`.
  - Kiểm tra đề tồn tại và mở (`TrangThai == "Mo"`).
  - Nếu đã có `KetQuaThi` trạng thái `DangLam` cho user → trả session hiện tại (cho phép tiếp tục).
  - Nếu `AllowMultipleAttempts == false` và user đã `HoanThanh` → trả `400 BadRequest` với message "Bạn đã hoàn thành đề thi này.".
  - Random câu hỏi theo `ChuDeId`, tạo `KetQuaThi` + `ChiTietKetQuaThi`, trả `StartThiResponse` chứa metadata và danh sách câu hỏi.
- `PUT /api/Thi/update/{ketQuaThiId}/{cauHoiId}` lưu đáp án từng câu (được `QuizScreen` sử dụng sau này).
- `POST /api/Thi/submit/{ketQuaThiId}` chấm điểm, tính `Diem`, `SoCauDung`, đánh dấu `TrangThai = "HoanThanh"`.

## 6. Giao tiếp API và payload mẫu

### 6.1 Danh sách đề thi đang mở

- Endpoint: `GET /api/DeThi/open`
- Response mẫu:

```json
[
  {
    "id": 12,
    "tenDeThi": "Toán 12 - Đại số",
    "chuDeId": 5,
    "trangThai": "Mo",
    "allowMultipleAttempts": true,
    "soCauHoi": 50,
    "thoiGianThi": 60,
    "ngayTao": "2025-10-24T03:20:00Z",
    "chuDe": { "id": 5, "tenChuDe": "Toán" }
  }
]
```

### 6.2 Khởi tạo bài thi

- Endpoint: `POST /api/Thi/start/{deThiId}` (Bearer token bắt buộc)
- Request body: none
- Response mẫu:

```json
{
  "ketQuaThiId": 321,
  "deThiId": 12,
  "tenDeThi": "Toán 12 - Đại số",
  "soCauHoi": 30,
  "thoiGianThi": 45,
  "ngayBatDau": "2025-10-31T01:35:10.123Z",
  "cauHois": [
    {
      "id": 901,
      "noiDung": "Hàm số y = x^2 có đạo hàm là?",
      "dapAnA": "2x",
      "dapAnB": "x^2",
      "dapAnC": "x",
      "dapAnD": null,
      "dapAnChon": null
    }
  ]
}
```

## 7. Xử lý lỗi & cạnh

- `_ExamTab` hiển thị spinner (`deThiProvider.loadingOpen`) và thông báo số đề tìm thấy; nút "Xóa bộ lọc" giúp reset nhanh nếu người dùng lọc quá hẹp.
- `ExamDetailScreen._startQuiz` đặc biệt kiểm tra chuỗi `SqlException` trong lỗi để chuyển thành message thân thiện. Các lỗi khác giữ nguyên để dễ debug.
- Nếu `ThiController.StartThi` trả `400` vì đã hoàn thành đề, provider lưu message "Bạn đã hoàn thành đề thi này." và UI hiển thị snackbar.
- Trường hợp không đủ câu hỏi (`BadRequest` từ backend) cũng được propagete tới `ThiProvider.error` → `_startQuiz` hiển thị.
- `RefreshIndicator` cho phép người dùng khôi phục khi mạng yếu; nếu call thất bại, snackbar thông báo lỗi từ `DeThiProvider.error`.
- Khi người dùng rời `QuizScreen`, `WillPopScope` cảnh báo mất tiến độ để tránh mất dữ liệu do lỗi thao tác.

## 8. Gợi ý kiểm thử

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Kiểm tra lọc + tìm kiếm | `flutter_test` với `pumpWidget` `_ExamTab` kết hợp provider fake | Đảm bảo filter theo keyword/chủ đề hoạt động đúng |
| Provider đề thi | Unit test với `mockito` cho `DeThiService` | Kiểm tra handling loading, error, cập nhật danh sách |
| StartThi happy path | Integration test .NET (`WebApplicationFactory`) | Đảm bảo endpoint chọn đúng số câu, tái sử dụng session `DangLam` |
| StartThi chặn làm lại | API test | User đã hoàn thành → nhận `400` |
| Quiz timer & auto submit | Widget test với `fakeAsync` hoặc manual QA | Đảm bảo tự động nộp khi hết giờ |

## 9. Ghi chú triển khai

- `DeThi.allowMultipleAttempts` cần được seed đúng trên backend; nếu để `false`, người dùng chỉ thi được một lần. UI hiện chưa hiển thị trạng thái này nên cân nhắc bổ sung label.
- `ExamDetailScreen` gọi `DeThiProvider.fetchOpenDeThis()` mỗi lần mở chi tiết. Nếu danh sách đề lớn, có thể tối ưu bằng cache với TTL hoặc kiểm tra `loadingOpen` trước.
- `QuizScreen` relies on `ThiProvider.currentSession`; nếu start API trả lỗi, chắc chắn `ThiProvider.reset()` được gọi để tránh session "mồ côi".
