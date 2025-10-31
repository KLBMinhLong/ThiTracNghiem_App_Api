# 🌙 CHẾ ĐỘ TỐI & QUẢN LÝ GIAO DIỆN - TÀI LIỆU CHI TIẾT

## 1. Tóm tắt luồng hoạt động

```
Người dùng mở tab "Tài khoản" (HomeScreen)
  → Switch "Chế độ tối" được binding theo theme hiện tại
  → Người dùng bật/tắt switch
       → gọi ThemeProvider.toggleTheme()
           → đảo trạng thái _isDarkMode
           → notifyListeners() để MaterialApp rebuild
           → lưu giá trị vào SharedPreferences với key "theme_mode"
  → Lần mở app tiếp theo, ThemeProvider._loadTheme() đọc SharedPreferences
       → gán _isDarkMode → themeMode = ThemeMode.dark/light
       → MaterialApp nhận themeMode và áp dụng dark/light ThemeData
```

## 2. Thành phần & vị trí mã nguồn

| Thành phần | Mô tả | File liên quan |
|------------|-------|----------------|
| Provider quản lý theme | Lưu trạng thái, đọc/ghi SharedPreferences, cung cấp ThemeData | `thitracnghiemapp/lib/providers/theme_provider.dart` |
| Đăng ký provider & áp dụng ThemeData | Bọc MaterialApp, gắn theme/darkTheme/themeMode | `thitracnghiemapp/lib/main.dart` |
| UI bật/tắt chế độ tối | `SwitchListTile` trong tab hồ sơ | `thitracnghiemapp/lib/screens/home_screen.dart` (`_ProfileTab` – dòng ~1740+) |
| Định nghĩa ThemeData chi tiết | Màu sắc, typography, component theme cho light/dark | `thitracnghiemapp/lib/themes/app_theme.dart` (legacy) & lặp lại trong `theme_provider.dart` |
| Lưu trữ local | `SharedPreferences` (gói `shared_preferences`) | Được gọi trong `ThemeProvider._loadTheme/_saveTheme` |

> Tham chiếu dựa trên nhánh `main` ngày 31/10/2025.

## 3. Provider `ThemeProvider`

- **Trạng thái**:
  - `_isDarkMode` (bool) – mặc định `false`, cập nhật sau khi đọc storage.
  - `_prefs` – giữ instance `SharedPreferences` để tái sử dụng (tránh khởi tạo lại).
  - `themeMode` trả về `ThemeMode.dark` hoặc `ThemeMode.light` dựa vào `_isDarkMode`.
- **Khởi tạo**: constructor gọi `_loadTheme()` (async) → lấy instance SharedPreferences → đọc key `theme_mode` → cập nhật `_isDarkMode` → `notifyListeners()`.
- **Toggle**: `toggleTheme()` đảo `_isDarkMode`, gọi `notifyListeners()` rồi `_saveTheme()`.
- **Thiết lập trực tiếp**: `setThemeMode(bool isDark)` cho phép ép chế độ cụ thể (phục vụ unit test hoặc setting khác).
- **Lưu trữ**: `_saveTheme()` gọi `_prefs?.setBool(_themeKey, _isDarkMode)` và swallow exception bằng `debugPrint`.
- **ThemeData**: file cung cấp 2 getter tĩnh `lightTheme`, `darkTheme` mô tả đầy đủ màu sắc, typography, AppBar/Card/Button/Input,... để MaterialApp tái sử dụng (giữ đồng bộ với theme cũ trước khi refactor).

## 4. Tích hợp trong `main.dart`

- `ChangeNotifierProvider<ThemeProvider>` được đăng ký ở cấp cao nhất (trong danh sách providers của `MultiProvider`).
- `MaterialApp` được bọc bởi `Consumer<ThemeProvider>` để rebuild khi `_isDarkMode` đổi.
- Props quan trọng:
  - `theme: ThemeProvider.lightTheme`
  - `darkTheme: ThemeProvider.darkTheme`
  - `themeMode: themeProvider.themeMode`
- Nhờ vậy, khi `notifyListeners()` được gọi, MaterialApp tự động chuyển đổi giữa hai bộ kèm theo tất cả widget con.

## 5. UI bật/tắt trong `_ProfileTab`

- `SwitchListTile` hiển thị nhãn "Chế độ tối" cùng icon `Icons.dark_mode_outlined`.
- `value` của switch dựa trên `theme.brightness == Brightness.dark` (theme hiện tại từ context).
- `onChanged` không cần giá trị, chỉ gọi `context.read<ThemeProvider>().toggleTheme()`.
- Card chứa switch có cùng phong cách (borderRadius 12, divider). Khi chuyển theme, card tự đổi màu vì phụ thuộc vào `Theme.of(context).colorScheme`.

## 6. Cấu hình ThemeData

### 6.1 Bộ màu mặc định (light)
- Primary: `Color(0xFF2196F3)`; Secondary: `0xFF03A9F4`.
- Surface/background: trắng & xám nhạt → tạo cảm giác sáng.
- Typography dùng `GoogleFonts.poppins` với `ScreenUtil` để scale kích thước theo màn hình.
- AppBar nền xanh, icon trắng; Card có border radius 8, shadow nhẹ.
- Button, Input, Chip, Dialog, SnackBar, BottomNavigationBar,... đều thiết kế đồng nhất.

### 6.2 Bộ màu dark
- Primary: `0xFF90CAF9` (xanh nhạt hơn để nổi bật trên nền tối).
- Background tổng thể: `0xFF121212`; Surface: `0xFF2C2C2C`.
- AppBar/BottomNavigationBar sử dụng màu surface tối, chữ trắng.
- Input có border `Colors.grey.shade700`, màu hint/text nhạt (`textSecondaryDark`).
- FloatingActionButton foreground `backgroundDark` để icon nổi bật.
- Divider, snackbar, dialog đều sử dụng tông tối nhưng vẫn giữ border radius như theme sáng.

### 6.3 Đồng bộ với legacy `AppTheme`
- File `themes/app_theme.dart` tồn tại để giữ theme cũ (nếu module khác dùng). `ThemeProvider` lặp lại cấu hình đó nhằm đảm bảo chuyển đổi liền mạch.
- Khi refactor, cân nhắc trích xuất `ThemeTokens` chung để tránh duplication.

## 7. Lưu trữ & khởi động lại ứng dụng

- Key lưu trữ: `theme_mode` (giá trị bool – true = dark).
- Lần đầu mở app: nếu chưa có key → `_isDarkMode = false` → giao diện sáng.
- Khi người dùng đổi sang dark: `_saveTheme()` ghi `true`. Lần khởi động tiếp theo, `_loadTheme()` đọc `true` → `themeMode = ThemeMode.dark` ngay lập tức (MaterialApp dùng theme tối từ khi build).
- Nếu có lỗi khi đọc/ghi SharedPreferences, provider log qua `debugPrint` và fallback về light mode (tránh crash).

## 8. Kiểm thử đề xuất

| Kiểm thử | Công cụ | Mục tiêu |
|----------|---------|----------|
| Unit test `ThemeProvider` | `flutter_test` + `shared_preferences` mock | Đảm bảo `toggleTheme()` đảo trạng thái & lưu storage; `_loadTheme()` đọc đúng giá trị. |
| Widget test `_ProfileTab` | `pumpWidget` với `ThemeProvider` giả | Xác minh switch phản ánh `themeMode` và gọi `toggleTheme()` khi onChanged. |
| Integration test MaterialApp | Pump `MaterialApp` + provider, đổi theme | Đảm bảo `Theme.of(context).brightness` cập nhật, màu sắc widget đổi. |
| Manual QA | Thiết bị thật trên Android/iOS | Chuyển qua lại dark/light, kill app mở lại kiểm tra lựa chọn được giữ. |

## 9. Ghi chú triển khai & mở rộng

- Nếu cần đồng bộ theme giữa thiết bị và backend, có thể mở rộng `setThemeMode` để gọi API lưu preference server-side.
- Để hỗ trợ "Theo hệ thống" (ThemeMode.system), có thể lưu thêm trạng thái thứ ba (enum) thay vì bool.
- Hiện `ThemeProvider` chứa full ThemeData (trùng với `AppTheme`). Nếu quy mô lớn, nên tách ra module riêng dùng `ThemeExtension` hoặc `ThemeTokens` để tránh trùng lặp.
- Khi thêm component mới, đảm bảo dùng màu từ `Theme.of(context).colorScheme` thay vì hard-code để hỗ trợ cả hai chế độ.
