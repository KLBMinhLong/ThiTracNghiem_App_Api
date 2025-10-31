# LUỒNG LÀM BÀI: TRẢ LỜI → LƯU ĐÁP ÁN → HẸN GIỜ → NỘP BÀI → HIỂN THỊ KẾT QUẢ

## 1. Tóm tắt luồng

```
ExamDetailScreen._startQuiz()
  → ThiProvider.reset()
  → ThiProvider.startThi(deThiId)
  → ThiService.startThi()
  → POST /api/Thi/start/{deThiId} (ThiController.StartThi)
  → QuizScreen nhận QuizSession (ketQuaThiId + câu hỏi + thời gian)

Người dùng chọn đáp án trong QuizScreen
  → _selectAnswer()
    → ThiProvider.updateDapAn(cauHoiId, dapAnChon)
    → ThiService.updateDapAn()
    → PUT /api/Thi/update/{ketQuaThiId}/{cauHoiId} (ThiController.UpdateDapAn)
    → ChiTietKetQuaThi.DapAnChon + DungHaySai được cập nhật
    → QuizScreen rebuild với selectedAnswer mới

Timer chạy (_startTimer)
  → Timer.periodic giảm _remainingSeconds
  → Khi về 0 → tự động gọi _submit()

Người dùng nhấn "Nộp bài" (hoặc auto submit)
  → _submit()
    → ThiProvider.submitThi()
    → ThiService.submitThi()
    → POST /api/Thi/submit/{ketQuaThiId} (ThiController.SubmitThi)
    → Tính điểm, cập nhật KetQuaThi.TrangThai = "HoanThanh"
    → Nhận SubmitThiResult (điểm, thống kê, chi tiết câu)
    → QuizScreen pushReplacement(ResultScreen)
    → KetQuaThiProvider.fetchKetQuaThiList() cập nhật lịch sử tab "Lịch sử"

ResultScreen
  → Render điểm số, tỷ lệ đúng, thống kê, bảng câu hỏi chi tiết
  → Nút "Về trang chủ" đưa người dùng trở lại HomeScreen
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File & hàm chính |
|------------|---------|------------------|
| Giao diện làm bài | Hiển thị câu hỏi, timer, điều hướng | `lib/screens/quiz_screen.dart` (`QuizScreen`, `_selectAnswer`, `_submit`, `_startTimer`) |
| Layout câu hỏi | Card nội dung câu, danh sách đáp án | `quiz_screen.dart` (`_QuestionBody`) |
| Thanh tiến độ | Hiển thị số câu đã trả lời, cho phép nhảy câu | `quiz_screen.dart` (`_ProgressHeader`) |
| Điều khiển cuối trang | Nút Trước/Tiếp/Nộp bài + loading | `quiz_screen.dart` (`_QuizControls`) |
| Provider bài thi | Lưu session hiện tại, lỗi, kết quả nộp | `lib/providers/thi_provider.dart` |
| Service bài thi | Gọi API `/api/Thi/*` | `lib/services/thi_service.dart` |
| API cập nhật đáp án | Lưu lựa chọn từng câu, kiểm tra quyền | `ThiTracNghiemApi/Controllers/ThiController.cs` (`UpdateDapAn`) |
| API nộp bài | Chấm điểm, tính số câu đúng, trả chi tiết | `ThiController.SubmitThi` |
| Mô hình session & kết quả | Đại diện QuizSession, SubmitThiResult | `lib/models/quiz_session.dart` |
| Màn hình kết quả | Trình bày điểm, thống kê, chi tiết từng câu | `lib/screens/result_screen.dart` |
| Provider lịch sử | Làm mới tab lịch sử sau khi nộp | `lib/providers/ket_qua_thi_provider.dart` (`fetchKetQuaThiList`) |

## 3. Giao diện QuizScreen

- **`QuizScreen` lifecycle**
  - `initState` gọi `_initialiseSession` → nếu chưa có session (ví dụ refresh), tự gọi `ThiProvider.startThi`.
  - `dispose` hủy timer và `ThiProvider.reset()` để tránh giữ session cũ.
  - `WillPopScope` → `_confirmExit` cảnh báo người dùng trước khi thoát khi đang dở dang.

- **Timer & auto submit**
  - `_startTimer(int seconds)` tạo `Timer.periodic` 1 giây, cập nhật `_remainingSeconds`.
  - Khi còn <= 1 giây: timer hủy, gọi `_submit` để tự động nộp.
  - AppBar hiển thị đếm ngược, đổi màu khi còn < 60 giây.

- **Thanh tiến độ `_ProgressHeader`**
  - Cho biết câu hiện tại và số câu đã trả lời (`selectedAnswer != null`).
  - Người dùng có thể chạm vào badge số câu để nhảy trực tiếp (gọi `onJumpTo`).
  - Badge đang chọn hiển thị gradient, badge đã trả lời có viền màu primary.

- **Thân câu hỏi `_QuestionBody`**
  - Hiển thị tiêu đề "Câu X" và nội dung `question.noiDung`.
  - Danh sách đáp án được lọc để bỏ option null/rỗng.
  - Khi chọn option (`InkWell.onTap`), gọi `onSelect(letter)` → `_selectAnswer`.
  - Option đã chọn hiển thị border + gradient, icon check và chữ đậm.

- **Điều khiển cuối trang `_QuizControls`**
  - Nút "Trước" disable nếu đang ở câu đầu.
  - Nút "Tiếp" hoặc "Nộp bài" tùy `isLast`. Khi nộp bài hiển thị spinner nếu `_submitting = true`.
  - Nút submit đổi màu xanh để nhấn mạnh hành động cuối.

## 4. Lưu đáp án từng câu

- **`QuizScreen._selectAnswer`**
  - Gọi `ThiProvider.updateDapAn` với `cauHoiId` và ký hiệu đáp án.
  - Sau await, nếu `provider.error` khác null → snackbar lỗi thông qua `UIHelpers.showErrorSnackBar`.

- **`ThiProvider.updateDapAn`**
  - Lấy `QuizSession` hiện tại, nếu null thì bỏ qua.
  - Gọi `ThiService.updateDapAn` → PUT `/api/Thi/update/{ketQuaThiId}/{cauHoiId}`.
  - Khi API thành công, dùng `session.copyWithUpdatedAnswer` để cập nhật `selectedAnswer` trong state và `notifyListeners()`.
  - Nếu `ApiException`, lưu `_error = e.message` → UI hiển thị.

- **`ThiService.updateDapAn`**
  - Gửi body `{ 'dapAnChon': letter }`.
  - Không parse response (API trả 200 OK rỗng), chỉ ném lỗi nếu status >= 400 (handled trong `ApiClient`).

- **`ThiController.UpdateDapAn`**
  - Resolve user từ token, kiểm tra `ketQuaThi.TaiKhoanId` trùng user (không thì `Forbid`).
  - Chặn cập nhật nếu `ketQuaThi.TrangThai == "HoanThanh"`.
  - Lấy `ChiTietKetQuaThi` tương ứng, cập nhật `DapAnChon` và so sánh với `CauHoi.DapAnDung` → set `DungHaySai`.
  - Lưu DB (`SaveChangesAsync`) rồi trả `Ok()`.

## 5. Nộp bài & cập nhật kết quả

- **`QuizScreen._submit`**
  - Guard `_submitting` để tránh double tap.
  - Gọi `ThiProvider.submitThi`, sau đó lấy `submitResult`.
  - Dừng timer, gọi `KetQuaThiProvider.fetchKetQuaThiList(onlyUserId)` chạy song song (không chờ) để refresh tab lịch sử.
  - `Navigator.pushReplacement(ResultScreen)` để người dùng xem kết quả, tránh quay lại màn làm bài.

- **`ThiProvider.submitThi`**
  - Đặt `_isLoading = true`, `_error = null`.
  - Gọi `ThiService.submitThi(ketQuaThiId)` → POST `/api/Thi/submit/{ketQuaThiId}`.
  - Lưu `SubmitThiResult` vào `_submitResult`, notify listeners. Lỗi được map tương tự `updateDapAn`.

- **`ThiService.submitThi`**
  - Parse JSON trả về thành `SubmitThiResult`, bao gồm điểm (`double`), số câu đúng, tổng câu, danh sách `ChiTietKetQuaThi`.

- **`ThiController.SubmitThi`**
  - Kiểm tra user và quyền truy cập kết quả (chỉ chủ sở hữu hoặc admin).
  - Chặn nộp lại nếu `TrangThai == "HoanThanh"`.
  - Duyệt `ChiTietKetQuaThi`, so sánh đáp án, tính `soCauDung`, cập nhật `DungHaySai` và `KetQuaThi.Diem`, `KetQuaThi.NgayNopBai`.
  - Làm tròn điểm 2 chữ số với thang 10.
  - Trả `SubmitThiResponse` chứa danh sách chi tiết đã được map sẵn cho frontend.

## 6. ResultScreen & đồng bộ lịch sử

- **`ResultScreen`**
  - Nhận `DeThi` + `SubmitThiResult` từ `QuizScreen`.
  - Tính % đúng (`round`) → xác định pass >= 50%.
  - Card điểm hiển thị gradient xanh/cam tùy kết quả, điểm dạng `X.Y/10`.
  - Thống kê số câu đúng/sai, tổng câu, tỷ lệ đúng.
  - `ExpansionTile` "Chi tiết từng câu hỏi" liệt kê `result.chiTiet`:
    - Số thứ tự, nội dung, `dapAnChon`, `dapAnDung`, icon đúng/sai.
  - Nút "Về trang chủ" pop đến route đầu (giữ session sạch).

- **`KetQuaThiProvider.fetchKetQuaThiList`**
  - Được gọi sau submit (không await) để lịch sử cập nhật ngay khi người dùng chuyển tab.
  - Nếu truyền `onlyUserId`, provider lọc danh sách cho user hiện tại.

## 7. API & payload mẫu

### 7.1 Lưu đáp án từng câu

- Endpoint: `PUT /api/Thi/update/{ketQuaThiId}/{cauHoiId}`
- Body:

```json
{ "dapAnChon": "A" }
```

- Response: `200 OK` (empty body). Lỗi phổ biến:
  - `400 BadRequest`: ModelState invalid (dapAnChon rỗng).
  - `403 Forbid`: User không sở hữu KetQuaThi.
  - `409/400`: Bài thi đã nộp (`TrangThai = HoanThanh`).

### 7.2 Nộp bài thi

- Endpoint: `POST /api/Thi/submit/{ketQuaThiId}`
- Response mẫu:

```json
{
  "diem": 7.5,
  "soCauDung": 15,
  "tongSoCau": 20,
  "chiTiet": [
    {
      "cauHoiId": 101,
      "noiDung": "Câu hỏi 1",
      "dapAnA": "2x",
      "dapAnB": "x^2",
      "dapAnC": "x",
      "dapAnD": null,
      "dapAnChon": "A",
      "dapAnDung": "A",
      "dungHaySai": true
    }
  ]
}
```

- Lỗi phổ biến:
  - `400 BadRequest`: "Bài thi đã được nộp." hoặc "Không tìm thấy câu hỏi nào".
  - `401 Unauthorized`: Token hết hạn.
  - `403 Forbid`: KetQuaThi không thuộc user.

## 8. Xử lý lỗi & kịch bản biên

- `ThiProvider.updateDapAn`/`submitThi` lưu `_error`; `QuizScreen` đọc sau mỗi thao tác và hiển thị snackbar.
- `_selectAnswer` không chặn user khi API lỗi nhưng giữ snackbar để user biết cần thử lại (answer local vẫn cập nhật – cân nhắc rollback nếu cần chặt chẽ hơn).
- Auto submit bảo đảm bài không bị bỏ quên khi hết giờ. Nếu `submitThi` lỗi (ví dụ mạng), `_submitting` set về false và snackbar hiện message; người dùng có thể thử lại.
- `WillPopScope` giúp tránh mất dữ liệu do back nhầm. Nếu user chọn "Thoát", `ThiProvider.reset()` đảm bảo provider sạch.
- `QuizScreen.dispose` luôn reset provider, tránh hiển thị session cũ khi người dùng vào đề thi khác.
- `ResultScreen` không phụ thuộc vào state provider (dữ liệu truyền qua constructor), tránh lỗi khi provider reset.

## 9. Gợi ý kiểm thử

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Widget test `_QuestionBody` | `flutter_test` với pumpWidget + tap | Đảm bảo chọn đáp án gọi callback và highlight đúng |
| Provider update answer | Unit test `ThiProvider` + `mockito` cho `ThiService` | Kiểm tra cập nhật state, xử lý lỗi API |
| Timer auto submit | Widget test với `fakeAsync` | Khi hết giờ → `_submit` được gọi đúng và không crash |
| Submit flow happy path | Integration test backend (`WebApplicationFactory`) | Điểm và chi tiết tính chính xác, `TrangThai` cập nhật |
| Submit khi đã nộp | API test | Đảm bảo controller trả `400` và frontend hiển thị snackbar |
| ResultScreen UI | Golden test | Kiểm tra layout điểm, màu sắc khi pass/fail |

## 10. Ghi chú triển khai

- Hiện tại `_selectAnswer` không debounce; nếu muốn giảm số request PUT có thể thêm delay hoặc batch (tùy yêu cầu nghiệp vụ).
- API `UpdateDapAn` không trả lại dữ liệu; nếu cần đồng bộ `DungHaySai` ngay sau khi trả lời, có thể mở rộng response hoặc gọi `submit` giả lập.
- `KetQuaThiProvider.fetchKetQuaThiList` đang lấy tất cả rồi filter phía client; cân nhắc thêm query `onlyUserId` server-side để giảm payload.
- Nếu cần hỗ trợ resume timer khi quay lại app, xem xét lưu thời điểm bắt đầu (`QuizSession.ngayBatDau`) và tính remaining theo thời gian thực.
- ResultScreen mới chỉ hiển thị chi tiết, chưa cho phép chia sẻ hoặc xuất PDF; các cải tiến này nên dùng `SubmitThiResult.chiTiet` làm nguồn dữ liệu.
