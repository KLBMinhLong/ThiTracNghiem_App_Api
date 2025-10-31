# CHỨC NĂNG CHAT GIẢI THÍCH BÀI THI (AI EXPLAIN)

## 1. Tóm tắt luồng

```
ResultReviewScreen (user nhấn Chat AI)
  → ChatProvider.setContext(ketQuaThiId)
  → showModalBottomSheet(_ChatSheet)
    → Người dùng nhập câu hỏi → _send()
      → ChatProvider.send(text)
        → thêm ChatMessage(role: 'user') vào danh sách
        → ChatService.sendMessage(ketQuaThiId, text)
          → POST /api/Chat/explain (ChatController.Explain)
            → Backend xác thực user & quyền xem KetQuaThi
            → Build context câu hỏi/đáp án → gọi OpenAI (nếu có API key)
            → Trả ChatMessageResponse(reply)
        → Provider thêm ChatMessage(role: 'assistant', reply)
        → _ChatSheet rebuild hiển thị tin nhắn + trạng thái gửi
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Vai trò | File & hàm chính |
|------------|---------|------------------|
| Entry point UI | Nút Chat AI trong xem chi tiết kết quả | `lib/screens/result_review_screen.dart` (`_openChat`, `_ChatSheet`) |
| Provider quản lý hội thoại | Lưu tin nhắn, trạng thái gửi, lỗi | `lib/providers/chat_provider.dart` |
| Model tin nhắn | Phân biệt user/assistant | `lib/models/chat_message.dart` |
| Service gọi API | POST `/api/Chat/explain` | `lib/services/chat_service.dart` |
| Đăng ký provider | Inject vào tree ngay khi app khởi chạy | `lib/main.dart` (ChangeNotifierProvider<ChatProvider>) |
| API Chat | Kiểm tra quyền, gọi OpenAI hoặc fallback tóm tắt | `ThiTracNghiemApi/Controllers/ChatController.cs` |
| DTO request/response | Validate dữ liệu, định dạng reply | `ThiTracNghiemApi/Dtos/Chat/*.cs` |

## 3. Giao diện & trải nghiệm người dùng

### 3.1 Kích hoạt từ ResultReviewScreen

- Action button trên AppBar và FAB "Chat với AI" cùng gọi `_openChat(context)`.
- Hàm `_openChat` lấy `ChatProvider` qua `context.read`, gọi `setContext(ketQuaThiId: detail.id)` để:
  - Gán session mới theo kết quả thi hiện tại.
  - Xoá các tin nhắn hoặc lỗi còn sót từ phiên trước.

### 3.2 Bottom sheet `_ChatSheet`

- Hiển thị logo AI, danh sách tin nhắn, banner lỗi (nếu có) và ô nhập.
- Trạng thái hiển thị:
  - **Empty**: icon + gợi ý "Bắt đầu trò chuyện".
  - **Đang gửi**: nút gửi đổi thành `CircularProgressIndicator` và disable để tránh spam.
  - **Tin nhắn**: căn phải cho user, căn trái cho assistant, gradient nền theo role.
- Khi nhấn gửi:
  - `_controller.text` được trim → `ChatProvider.send`.
  - TextField tự clear.
  - Nếu provider.sending = true, nút gửi bị disable.
- Banner lỗi: khi provider.error != null, hiển thị hộp đỏ với message trả về từ provider.

## 4. Provider & service phía Flutter

### 4.1 `ChatProvider`

- Thuộc tính chính:
  - `_ketQuaThiId`: kết quả đang được hỏi.
  - `_messages`: danh sách `ChatMessage` (immutable getter qua `List.unmodifiable`).
  - `_sending`: bool hiển thị loading.
  - `_error`: thông báo lỗi thân thiện (chuỗi).
- `setContext`
  - Chỉ reset khi ID thay đổi → tránh mất lịch sử nếu mở lại sheet cùng kết quả.
- `send(String text)`
  - Bỏ qua khi text rỗng hoặc `_ketQuaThiId` null (phòng trường hợp chưa gọi `setContext`).
  - Push tin nhắn user ngay lập tức để phản hồi tức thời.
  - Gọi `ChatService.sendMessage`; khi thành công push tin nhắn assistant.
  - Bắt mọi exception, convert thành `_error = e.toString()`.
  - Dù thành công hay thất bại đều set `_sending = false` và `notifyListeners()`.

### 4.2 `ChatService`

- Dùng `ApiClient.post` tới `/api/Chat/explain` với payload `{ ketQuaThiId, message }`.
- Kiểm tra response dạng `{ reply: string }`; nếu khác, ném `Exception('Phản hồi không hợp lệ từ máy chủ')`.
- `ApiClient` sẽ tự động gắn JWT và xử lý mã lỗi (ném `ApiException`).

## 5. Backend ChatController

### 5.1 Quy trình `Explain`

1. Validate request (`[Required]`): thiếu message → `400 BadRequest`.
2. Resolve user ID qua `User.ResolveUserIdAsync`; nếu người dùng chưa đăng nhập → `401`.
3. Truy vấn `KetQuaThi` bao gồm `DeThi` và `ChiTietKetQuaThi` + `CauHoi`.
4. Kiểm tra quyền sở hữu: user thường chỉ được xem kết quả của mình; admin xem mọi kết quả.
5. Xây dựng "context" bằng `StringBuilder`:
   - Tổng quan bài thi (tên, ngày, điểm).
   - Liệt kê từng câu hỏi + đáp án + lựa chọn của người dùng.
6. Lấy biến môi trường:
   - `OPENAI_API_KEY`: mở khoá gọi OpenAI.
   - `OPENAI_MODEL`: mặc định `gpt-4o-mini` nếu không set.
7. Nếu có API key:
   - Tạo payload Chat Completions (system prompt tiếng Việt hướng dẫn).
   - Gửi HTTP POST tới `https://api.openai.com/v1/chat/completions`.
   - Mã lỗi hoặc exception → fallback `SimpleExplainReply` + message cảnh báo.
8. Nếu không có API key:
   - Trả về fallback `SimpleExplainReply` + nhắc cấu hình biến môi trường.

### 5.2 Fallback `SimpleExplainReply`

- Sinh văn bản tóm tắt từng câu với đáp án đúng và lựa chọn của thí sinh.
- Dùng khi AI không khả dụng để đảm bảo người dùng vẫn nhận được phản hồi.

### 5.3 DTOs

- `ChatMessageRequest`
  - `KetQuaThiId`: int, required.
  - `Message`: string, required.
- `ChatMessageResponse`
  - `Reply`: string, nội dung trả về cho client.

## 6. Giao tiếp API & payload mẫu

### Request

```http
POST /api/Chat/explain
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "ketQuaThiId": 45,
  "message": "Giải thích giúp tôi câu 3"
}
```

### Response (AI thành công)

```json
{
  "reply": "Câu 3 thuộc chủ đề..." 
}
```

### Response (fallback)

```json
{
  "reply": "Tóm tắt nhanh đề và đáp án: Câu 1: ... (Lưu ý: Gọi AI thất bại 401 Unauthorized)"
}
```

## 7. Xử lý lỗi & UX

- Client hiển thị lỗi API qua `_error` (ví dụ `Unauthorized`, `Phản hồi không hợp lệ`, thông điệp fallback).
- Khi server trả fallback, thông điệp chứa chú thích để người dùng biết AI không chạy.
- Nếu `ketQuaThiId` không thuộc user → API trả `403 Forbid`; provider nhận exception → `_error` hiển thị.
- Tốc độ phản hồi phụ thuộc vào OpenAI; `ChatProvider` giữ `_sending` để block gửi liên tiếp.

## 8. Cấu hình & triển khai

- Đặt biến môi trường trên backend:
  - `OPENAI_API_KEY`: API key hợp lệ của OpenAI.
  - `OPENAI_MODEL`: (tùy chọn) tên model, ví dụ `gpt-4o-mini`, `gpt-4.1-mini`.
- Nếu không cấu hình, người dùng vẫn nhận được tóm tắt, nhưng không có giải thích chi tiết.
- Yêu cầu mạng outbound từ server tới `api.openai.com` (HTTPS).

## 9. Gợi ý kiểm thử

| Test | Công cụ | Mục tiêu |
|------|---------|----------|
| Unit test ChatProvider | `flutter_test` + mock `ChatService` | Đảm bảo `messages` và `_sending` cập nhật đúng, lỗi được lưu |
| Widget test `_ChatSheet` | `pumpWidget` + giả lập provider | Kiểm tra hiển thị empty state, tin nhắn, banner lỗi |
| API integration (OpenAI mock) | `WebApplicationFactory` + `HttpMessageHandler` mock | Xác minh controller gửi đúng payload, xử lý fallback |
| Không có API key | Manual / integration | Đảm bảo fallback chứa thông báo cấu hình |
| Quyền truy cập | API test | User khác truy cập kết quả → `403`; admin truy cập được |

## 10. Hạn chế & đề xuất

- Hiện tại hội thoại không lưu server-side; khi đóng sheet hoặc chuyển kết quả khác, lịch sử bị xoá.
- Không có cơ chế rate-limit phía client. Cần cân nhắc throttling nếu triển khai rộng.
- Fallback text khá đơn giản; có thể nâng cấp bằng cách chạy rule-base chi tiết hơn.
- Chưa hiển thị thời gian phản hồi hoặc avatar AI. Có thể cải thiện UX bằng timestamp.
- Khi OpenAI trả lỗi lớn (429, 500) -> fallback message hiển thị mã lỗi; cân nhắc dịch sang tiếng Việt thân thiện hơn.
