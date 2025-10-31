# LUỒNG LỊCH SỬ BÀI THI & XEM CHI TIẾT KẾT QUẢ

## 1. Tóm tắt luồng

```
HomeScreen._loadInitialData()
  → KetQuaThiProvider.fetchKetQuaThiList(onlyUserId: currentUser)
  → KetQuaThiService.fetchKetQuaThis()
  → GET /api/KetQuaThi (KetQuaThiController.GetKetQuaThis)
  → KetQuaThiProvider.ketQuaThiList cập nhật → _HistoryTab render

Người dùng mở tab "Lịch sử"
  → _HistoryTab (Consumer<KetQuaThiProvider>)
    → Loading skeleton nếu dữ liệu chưa sẵn
    → EmptyStateWidget nếu danh sách rỗng
    → ListView.separated hiển thị từng KetQuaThiSummary
    → Swipe-to-delete (restrictToUserId) → KetQuaThiProvider.deleteKetQuaThi → DELETE /api/KetQuaThi/{id}

Chọn một kết quả
  → HomeScreen._openResultReview(summary)
    → KetQuaThiProvider.fetchKetQuaThi(summary.id)
    → KetQuaThiService.fetchKetQuaThi(id)
    → GET /api/KetQuaThi/{id} (KetQuaThiController.GetKetQuaThi)
    → Provider.selectedKetQuaThi set → push ResultReviewScreen(detail)

ResultReviewScreen(detail)
  → Tính tổng câu đúng / tổng câu
  → Liệt kê từng câu với trạng thái đúng/sai, đáp án người dùng và đáp án đúng
  → Nút Chat AI mở ChatProvider (setContext) → POST /api/Chat/explain (ngoài phạm vi chính nhưng được kích hoạt tại đây)
  → Khi pop → HomeScreen.clearSelected()
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File & hàm chính |
|------------|---------|------------------|
| Tải dữ liệu lịch sử ban đầu | Gọi provider sau khi load màn hình | `lib/screens/home_screen.dart` (`HomeScreen._loadInitialData`) |
| Tab lịch sử | Hiển thị list, refresh, swipe delete, view detail | `lib/screens/home_screen.dart` (`_HistoryTab`) |
| Điều hướng chi tiết | Fetch detail rồi mở review screen | `lib/screens/home_screen.dart` (`_openResultReview`) |
| Provider lịch sử | Quản lý danh sách, chi tiết, xóa | `lib/providers/ket_qua_thi_provider.dart` |
| Service lịch sử | Gọi API `/api/KetQuaThi` | `lib/services/ket_qua_thi_service.dart` |
| Mô hình dữ liệu | `KetQuaThiSummary`, `KetQuaThiDetail`, chi tiết câu | `lib/models/ket_qua_thi.dart`, `lib/models/chi_tiet_ket_qua_thi.dart` |
| API danh sách/chi tiết/xóa kết quả | Authorize người dùng, filter admin | `ThiTracNghiemApi/Controllers/KetQuaThiController.cs` |
| Màn xem lại kết quả | UI chi tiết câu hỏi + Chat AI entrypoint | `lib/screens/result_review_screen.dart` |
| Chat Provider (tuỳ chọn) | Chat giải thích kết quả | `lib/providers/chat_provider.dart`, `lib/services/chat_service.dart` |

## 3. Giao diện tab "Lịch sử"

### 3.1 Render & trạng thái

- `Consumer<KetQuaThiProvider>` đọc `isLoading`, `ketQuaThiList`, `error`.
- Nếu `provider.isLoading && provider.ketQuaThiList == null` → hiển thị spinner trong `ListView` (luôn cho phép kéo refresh).
- Khi có dữ liệu:
  - Nếu `restrictToUserId != null`, danh sách được lọc client-side, nhưng server đã giới hạn nếu không phải admin.
  - `EmptyStateWidget` với icon lịch sử nếu không có mục.
  - `ListView.separated` hiển thị `Card` cho mỗi `KetQuaThiSummary` gồm: tên đề, ngày thi (`UIHelpers.formatDateVN`), điểm (nếu có), badge trạng thái (`Hoàn thành`/`Đang làm`).

### 3.2 Swipe-to-delete

- `Dismissible` chỉ hoạt động khi `restrictToUserId` khớp với chủ sở hữu; admin xem toàn bộ nhưng không xoá hộ người khác bằng cử chỉ này.
- `confirmDismiss` hiển thị hộp thoại qua `UIHelpers.showConfirmDialog`.
- Khi người dùng xác nhận, gọi `KetQuaThiProvider.deleteKetQuaThi(summary.id)`:
  - Thành công → snackbar thành công.
  - Thất bại → đọc `provider.error` để hiển thị snackbar lỗi.
- Background swipe hiển thị nền đỏ + icon trash.

### 3.3 Refresh

- `RefreshIndicator.onRefresh` gọi lại `fetchKetQuaThiList` với `page` hiện tại và `onlyUserId` (nếu có) để đồng bộ.

## 4. Chi tiết kết quả (ResultReviewScreen)

- `HomeScreen._openResultReview` fetch detail trước khi điều hướng, tránh màn hình trắng.
- Sau khi pop khỏi `ResultReviewScreen`, gọi `provider.clearSelected()` để tránh giữ reference.

### 4.1 Header & tóm tắt

- AppBar hiển thị tên đề thi, nút "Chat AI" ở action.
- Card tổng kết màu xanh/cam tuỳ tỷ lệ đúng ≥ 50%.
- Hiển thị `correctCount/totalCount` và phần trăm chính xác.

### 4.2 Danh sách câu hỏi

- `ListView.separated` với `Card` từng câu:
  - Badge số thứ tự, badge trạng thái đúng/sai.
  - Nội dung câu hỏi, đáp án A/B/C/D (ẩn những đáp án trống).
  - Highlight đáp án đúng bằng border xanh, đáp án người chọn sai bằng đỏ.
  - Thông tin "Bạn: X" nếu người dùng chọn.

### 4.3 Chat AI (tuỳ chọn)

- Nút trong AppBar và FAB mở bottom sheet `_ChatSheet`.
- `ChatProvider.setContext(ketQuaThiId)` xoá lịch sử chat cũ khi xem kết quả khác.
- Gửi câu hỏi gọi `ChatService.sendMessage` → POST `/api/Chat/explain` với `{ketQuaThiId, message}`.
- Hiển thị danh sách tin nhắn, trạng thái gửi (`sending`), và thông báo lỗi nếu có.

## 5. Provider & Service

### 5.1 `KetQuaThiProvider`

- Thuộc tính: `_ketQuaThiList`, `_selectedKetQuaThi`, `_isLoading`, `_error`, `_lastFilterUserId`.
- `fetchKetQuaThiList(page, onlyUserId)`:
  - Gọi `KetQuaThiService.fetchKetQuaThis` (GET `/api/KetQuaThi`).
  - Nếu `onlyUserId` != null, filter client-side theo `taiKhoan.id`.
  - Lưu `_lastFilterUserId` để `refetchWithLastFilter()` dùng lại.
- `fetchKetQuaThi(id)` → GET `/api/KetQuaThi/{id}`.
- `deleteKetQuaThi(id)` → DELETE `/api/KetQuaThi/{id}`; cập nhật danh sách và xoá chi tiết nếu đang mở.

### 5.2 `KetQuaThiService`

- `fetchKetQuaThis` gửi query `page`, `pageSize` (mặc định 10) và parse `PaginatedResponse<KetQuaThiSummary>`.
- `fetchKetQuaThi` trả `KetQuaThiDetail` (bao gồm `chiTiet`).
- `deleteKetQuaThi` không parse response (204 NoContent).

## 6. Backend API

### 6.1 `GET /api/KetQuaThi`

- Bắt buộc auth.
- Nếu user không phải admin → tự động filter theo `TaiKhoanId` (tránh truy cập kết quả người khác).
- Trả JSON `{ total, items }` với `DeThi` & `ChuDe` tối thiểu cần thiết, `TaiKhoan` chỉ hiển thị cho admin.

### 6.2 `GET /api/KetQuaThi/{id}`

- Bắt buộc auth.
- Admin xem mọi kết quả; user thường chỉ xem của mình (`Forbid` nếu không).
- Trả về chi tiết đầy đủ: điểm, số câu, thời gian, danh sách `ChiTietKetQuaThiDto`.

### 6.3 `DELETE /api/KetQuaThi/{id}`

- Cho phép chủ sở hữu hoặc admin xoá.
- Xoá `ChiTietKetQuaThi` trước để tránh lỗi ràng buộc khoá ngoại (sử dụng `ExecuteDeleteAsync`).
- Trả `204 NoContent` nếu thành công.

## 7. Giao tiếp API mẫu

### 7.1 Danh sách kết quả

```
GET /api/KetQuaThi?page=1&pageSize=10
Authorization: Bearer <JWT>
```

Response rút gọn:

```json
{
  "total": 2,
  "items": [
    {
      "id": 45,
      "diem": 8.5,
      "soCauDung": 17,
      "trangThai": "HoanThanh",
      "ngayThi": "2025-10-30T08:11:00Z",
      "ngayNopBai": "2025-10-30T08:41:15Z",
      "deThi": {
        "id": 12,
        "tenDeThi": "Toán 12 - Đại số",
        "thoiGianThi": 45,
        "chuDe": { "id": 5, "tenChuDe": "Toán" }
      }
    }
  ]
}
```

### 7.2 Chi tiết kết quả

```
GET /api/KetQuaThi/45
Authorization: Bearer <JWT>
```

```json
{
  "id": 45,
  "diem": 8.5,
  "soCauDung": 17,
  "tongSoCau": 20,
  "trangThai": "HoanThanh",
  "ngayThi": "2025-10-30T08:11:00Z",
  "ngayNopBai": "2025-10-30T08:41:15Z",
  "deThi": {
    "id": 12,
    "tenDeThi": "Toán 12 - Đại số",
    "thoiGianThi": 45
  },
  "chiTiet": [
    {
      "cauHoiId": 901,
      "noiDung": "Hàm số y = x^2 có đạo hàm là?",
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

### 7.3 Xoá kết quả

```
DELETE /api/KetQuaThi/45
Authorization: Bearer <JWT>
```

## 8. Xử lý lỗi & tình huống đặc biệt

- `KetQuaThiProvider.fetchKetQuaThiList` bắt `ApiException` và lưu message; `_HistoryTab` hiện spinner hoặc empty mà không crash.
- Khi xóa thất bại, provider giữ `_error` để snackbar hiển thị lý do (ví dụ quyền hạn, lỗi mạng).
- `ResultReviewScreen` yêu cầu `KetQuaThiDetail`. Nếu fetch trả null (ví dụ bị xóa trong lúc xem), `_openResultReview` không điều hướng.
- Chat AI: nếu server trả lỗi hoặc không có `reply`, `ChatProvider` set `_error` → hiển thị banner đỏ trong sheet.
- Admin: `restrictToUserId` null → danh sách hiển thị đầy đủ; Dismissible bị chặn bằng điều kiện trong `confirmDismiss` để tránh xoá nhầm.

## 9. Gợi ý kiểm thử

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Provider fetch list | Unit test với `mockito` cho `KetQuaThiService` | Kiểm tra filter `onlyUserId`, cập nhật state |
| History tab widget | `flutter_test` pump `_HistoryTab` + fake provider | Xác minh loading, empty, list, swipe delete |
| Delete confirmation | Widget test sử dụng `tester.drag` và `showDialog` mock | Đảm bảo chỉ xóa khi user confirm |
| API authorization | Integration test .NET | User không phải chủ sở hữu → `Forbid` khi GET/DELETE kết quả người khác |
| Result review UI | Golden test | Đảm bảo hiển thị đúng/sai với màu sắc phù hợp |

## 10. Ghi chú triển khai

- Hiện filter admin vẫn load toàn bộ kết quả rồi filter client; nếu khối lượng lớn, cân nhắc thêm query `userId` trên API để phân trang hiệu quả.
- `ResultReviewScreen` không hiển thị đồng bộ audio/hình ảnh; nếu đề thi có `HinhAnh`/`AmThanh`, cần bổ sung widget hiển thị trong tương lai.
- Chat AI phụ thuộc endpoint `/api/Chat/explain`; khi triển khai chính thức cần kiểm soát quota và fallback khi service tạm ngưng.
- Sau khi xoá kết quả, lịch sử được cập nhật ngay tại provider; nếu người dùng mở review của bản vừa xoá, cần xử lý gracefully (đã được `_openResultReview` bảo vệ).
