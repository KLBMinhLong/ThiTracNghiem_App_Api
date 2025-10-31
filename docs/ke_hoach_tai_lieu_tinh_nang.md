# 📚 Danh Sách Chức Năng & Kế Hoạch Tài Liệu

Tài liệu này liệt kê toàn bộ chức năng chính của hệ thống Smart Test cùng trạng thái tài liệu hiện tại. Dùng làm checklist để soạn tài liệu chi tiết cho từng module.

> Đã hoàn thành: ✅ | Đang viết/Chưa có: ⏳

## 1. Xác Thực & Tài Khoản

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Đăng ký tài khoản | Form đăng ký, gửi API `/Auth/register`, trả JWT | `register_screen.dart`, `AuthProvider.register`, `AuthController.Register` | ✅ `docs/quy_trinh_dang_ky.md` |
| Đăng nhập thường | Username/email + mật khẩu, 2FA optional | `login_screen.dart`, `AuthProvider.login`, `/Auth/login` | ✅ `docs/quy_trinh_dang_nhap.md` |
| Đăng nhập Google | GoogleSignIn → `/Auth/login/google` | `AuthProvider.loginWithGoogle`, `AuthController.LoginWithGoogle` | ✅ (trong tài liệu đăng nhập) |
| Quên/đặt lại mật khẩu | Gửi email, token reset | `forgot_password_screen.dart`, `AuthProvider.sendPasswordResetEmail`, `/Auth/forgot-password` | ✅ `docs/quy_trinh_quen_mat_khau.md` |
| Xác thực 2 bước (2FA) | Bật/tắt, quét QR, verify code khi đăng nhập | `_TwoFaTile` trong `home_screen.dart`, `AuthProvider.setupTwoFa`, `/Auth/login-2fa` | ⏳ |
| Quản lý hồ sơ người dùng | Chỉnh sửa thông tin, đổi mật khẩu, logout | `_ProfileTab`, `AuthProvider.updateProfile`, `/Auth/me` | ⏳ |

## 2. Luồng Thi & Bài Thi

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Danh sách đề thi | Lọc theo chủ đề, tìm kiếm, xem chi tiết | `_ExamTab` trong `home_screen.dart`, `DeThiProvider.fetchOpenDeThis`, `/DeThi` API | ✅ `docs/quy_trinh_thi_trac_nghiem.md` |
| Bắt đầu bài thi | Khởi tạo KetQuaThi, chọn câu hỏi ngẫu nhiên | `QuizScreen`, `ThiProvider.startThi`, `/Thi/start/{deThiId}` | ✅ `docs/quy_trinh_thi_trac_nghiem.md` |
| Trả lời & lưu đáp án | Chọn đáp án, autosave theo câu | `_QuestionBody`, `ThiProvider.updateDapAn`, `/Thi/update/{ketQuaThiId}/{cauHoiId}` | ✅ `docs/huong_dan_thuc_hien_bai_thi.md` |
| Hẹn giờ & kiểm soát rời bài | Đếm ngược, xác nhận thoát | `QuizScreen` timer logic, `WillPopScope` | ✅ `docs/huong_dan_thuc_hien_bai_thi.md` |
| Nộp bài & chấm điểm | Tính điểm, lưu kết quả, hiển thị ResultScreen | `ThiProvider.submitThi`, `ThiController.SubmitThi`, `ResultScreen` | ✅ `docs/huong_dan_thuc_hien_bai_thi.md` |
| Xem lịch sử kết quả | Lịch sử theo user, filter admin | `_HistoryTab`, `KetQuaThiProvider.fetchKetQuaThiList`, `/KetQuaThi` | ✅ `docs/quy_trinh_lich_su_lam_bai.md` |
| Xem chi tiết bài làm | Hiển thị đúng/sai, chat giải thích | `ResultReviewScreen`, `KetQuaThiProvider.fetchKetQuaThi`, `/KetQuaThi/{id}` | ✅ `docs/quy_trinh_lich_su_lam_bai.md` |
| Chat giải thích bài làm | Gửi câu hỏi tới AI giải thích | `ChatProvider`, `ChatService`, `/Chat/explain` | ✅ `docs/huong_dan_giai_thich_cau_hoi_chat.md` |

## 3. Bảng Điều Khiển Quản Trị (Admin)

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Quản lý người dùng | Tìm kiếm, phân trang, tạo/sửa/xóa, gán vai trò, khóa tài khoản | `admin_dashboard_screen.dart` (Users tab), `UsersProvider`, `UsersController` | ✅ `docs/tai_lieu_quan_ly_nguoi_dung_admin.md` |
| Quản lý chủ đề | CRUD chủ đề, tìm kiếm | `admin_dashboard_screen.dart` (Topics tab), `ChuDeProvider`, `ChuDeController` | ✅ `docs/tai_lieu_quan_ly_chu_de_admin.md` |
| Quản lý câu hỏi | CRUD câu hỏi, bộ lọc, import Excel | Questions tab, `CauHoiProvider`, `CauHoiController`, `/CauHoi/import` | ✅ `docs/tai_lieu_quan_ly_cau_hoi_admin.md` |
| Quản lý đề thi | CRUD đề thi, bộ lọc trạng thái, cấu hình đa lượt | Exams tab, `DeThiProvider`, `DeThiController` | ✅ `docs/tai_lieu_quan_ly_de_thi_admin.md` |
| Quản lý liên hệ/góp ý | Danh sách contact, xem chi tiết, cập nhật trạng thái | Contacts tab, `LienHeProvider`, `LienHeController` | ✅ `docs/huong_dan_quan_ly_lien_he.md` |
| Điều phối đa phân hệ | Navigation rail, responsive layout | `admin_dashboard_screen.dart` | ⏳ |

## 4. Giao Tiếp & Hỗ Trợ

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Góp ý từ người dùng | Gửi phản hồi, xem lịch sử cá nhân | `_ContactTab`, `LienHeProvider.createLienHe`, `/LienHe` | ✅ `docs/huong_dan_quan_ly_lien_he.md` |
| Bình luận đề thi | CRUD bình luận theo đề | `ExamDetailScreen`, `BinhLuanProvider`, `/BinhLuan` | ✅ `docs/huong_dan_tinh_nang_binh_luan.md` |
| Email thông báo | Gửi email SMTP (quên mật khẩu, hỗ trợ) | `SmtpEmailSender`, SMTP config | ✅ (bao quát trong tài liệu quên mật khẩu) |

## 5. Phân Tích & Báo Cáo

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Dashboard thống kê người dùng | Tổng số bài thi, điểm TB, cao nhất | `_SummaryCard` trong `StatisticsScreen` | ✅ `docs/huong_dan_bieu_do_thong_ke.md` |
| Biểu đồ điểm theo thời gian | Line chart với `fl_chart` | `_ScoreOverTimeCard` | ✅ `docs/huong_dan_bieu_do_thong_ke.md` |
| Điểm trung bình theo chủ đề | Bar chart | `_AverageByTopicCard` | ✅ `docs/huong_dan_bieu_do_thong_ke.md` |
| Export dữ liệu (kế hoạch) | Chưa triển khai | N/A | ⏳ |

## 6. Giao Diện & Trải Nghiệm Người Dùng

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Splash screen có logo | Hiển thị tối thiểu 2 giây, kiểm tra session | `SplashScreen`, `AuthProvider.initialize` | ⏳ |
| Đổi logo đăng nhập | Logo asset trong login | `login_screen.dart` | ⏳ |
| Điều hướng chính với BottomNav | 4 tab chính | `HomeScreen` | ⏳ |
| Chế độ sáng / tối | Toggle lưu vào SharedPreferences | `ThemeProvider`, Switch ở `_ProfileTab` | ✅ `docs/huong_dan_che_do_toi.md` |
| Responsive UI | ScreenUtil, adaptive layout admin | `UIHelpers`, `admin_dashboard_screen.dart` | ⏳ |

## 7. Backend API & Hạ Tầng

| Chức năng | Mô tả | Thành phần chính | Tài liệu |
|-----------|------|------------------|---------|
| Cấu hình JWT & bảo mật | Issuer/Audience/Signing key, middleware | `Program.cs`, `appsettings.json` | ⏳ |
| Migration & schema | EF Core migrations, relationships | `Migrations/` | ⏳ |
| Seed dữ liệu mặc định | Roles, admin account (nếu có) | `Program.cs` seeding (kiểm tra) | ⏳ |
| Tài liệu API tổng quan | Danh sách endpoint | `ThiTracNghiemApi.http` | ⏳ |

## 8. Trạng Thái Tài Liệu Hiện Tại

- ✅ Hoàn thành: Đăng ký, Đăng nhập (bao gồm Google & 2FA flow), Quên mật khẩu.
- ⏳ Đang chờ viết: Tất cả chức năng còn lại trong bảng trên.
- Đề xuất thứ tự ưu tiên kế tiếp:
  1. Luồng thi & nộp bài (quan trọng nhất cho nghiệp vụ).
  2. Bảng điều khiển quản trị (người dùng, đề thi, câu hỏi).
  3. Thống kê & biểu đồ.
  4. Các tính năng trải nghiệm (dark mode, splash).
  5. Tổng quan backend & hạ tầng.

---

Sử dụng file này làm checklist. Khi hoàn thành một tài liệu chức năng, cập nhật cột "Tài liệu" sang ✅ và liên kết tới file tương ứng.