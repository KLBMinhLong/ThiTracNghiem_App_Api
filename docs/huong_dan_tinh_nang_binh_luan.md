# BINH LUAN DE THI - TAI LIEU CHI TIET

## 1. Tom tat luong

```
ExamDetailScreen.initState
  -> BinhLuanProvider.fetchComments(deThiId)
  -> BinhLuanService.fetchByDeThi()
  -> GET /api/BinhLuan/dethi/{deThiId} (BinhLuanController.GetBinhLuans)
  -> PaginatedResponse<BinhLuan> + thong tin tai khoan tac gia

Nguoi dung go noi dung va nhan nut Gui
  -> _submitComment() validate 5-500 ky tu
  -> BinhLuanProvider.createComment()
  -> BinhLuanService.createBinhLuan()
  -> POST /api/BinhLuan (BinhLuanController.CreateBinhLuan)
  -> Provider chen comment moi vao dau danh sach, tang total

Mo menu tren comment cua chinh minh
  -> _showEditComment() -> modal bottom sheet
  -> BinhLuanProvider.updateComment()
  -> PUT /api/BinhLuan/{id} (BinhLuanController.UpdateBinhLuan)
  -> Provider thay noi dung comment trong bo nho cache

Chon Xoa
  -> UIHelpers.showConfirmDialog()
  -> BinhLuanProvider.deleteComment()
  -> DELETE /api/BinhLuan/{id} (BinhLuanController.DeleteBinhLuan)
  -> Provider loc bo comment + giam dem total
```

## 2. Thanh phan tham gia & vi tri ma nguon

| Buoc | Mo ta | File lien quan |
|------|-------|----------------|
| Nap comments | Goi API phan trang theo de thi | `lib/providers/binh_luan_provider.dart` (`fetchComments`) |
| UI hien thi | Danh sach, EmptyState, menu sua/xoa | `lib/screens/exam_detail_screen.dart` (`Consumer<BinhLuanProvider>`) |
| Form tao moi | TextField + gradient send button | `lib/screens/exam_detail_screen.dart` (`_submitComment`) |
| Modal chinh sua | `showModalBottomSheet` + Form validator | `lib/screens/exam_detail_screen.dart` (`_showEditComment`) |
| Xac nhan xoa | Thong bao tu UIHelpers | `lib/screens/exam_detail_screen.dart` (`_confirmDeleteComment`) |
| Provider logic | Quan ly PaginatedResponse, caching, error | `lib/providers/binh_luan_provider.dart` |
| Service REST | `/api/BinhLuan` GET/POST/PUT/DELETE | `lib/services/binh_luan_service.dart` |
| Model comment | Parse JSON, copyWith, embed user | `lib/models/binh_luan.dart` |
| API backend | Endpoint + auth/role checks | `ThiTracNghiemApi/Controllers/BinhLuanController.cs` |
| DTO validate | `[StringLength(500, MinimumLength = 5)]` | `ThiTracNghiemApi/Dtos/BinhLuan` |

> Thong tin tham chieu theo commit 31/10/2025. Neu ten ham thay doi, tim theo ten duoc liet ke trong bang.

## 3. Trai nghiem nguoi dung tren Flutter

### 3.1 Loading & refresh

- `RefreshIndicator` tren `ExamDetailScreen` goi `fetchComments()` giup dong bo danh sach khi keo xuong.
- Trong `Consumer<BinhLuanProvider>`, khi `isLoading == true` va `comments == null`, UI hien spinner va thong diep "Dang tai binh luan...".
- Neu danh sach trong, `EmptyStateWidget` moi nguoi dung la comment dau tien.

### 3.2 Dang binh luan

- `_submitComment` trim text, check ranh gioi 5 <= length <= 500. Neu vi pham, snackbar thong bao bang `UIHelpers.showInfoSnackBar`.
- Khi hop le: set `_sendingComment = true`, goi `provider.createComment`. True/false duoc dung de disable nut send va hien `CircularProgressIndicator` nho.
- Sau khi API thanh cong: goi `_loadComments()` de refresh tu server, xoa TextField, hien snackbar "Da dang binh luan".
- Backend vao controller se trim noi dung lan nua va gan `NgayTao = DateTime.UtcNow`.

### 3.3 Chinh sua binh luan

- Chi chu so huu (so sanh `comment.taiKhoan?.id` voi `AuthProvider.currentUser?.id`) moi thay menu.
- `_showEditComment` mo bottom sheet gom `Form` validator, 3-6 dong, reused logic 5-500 ky tu.
- Sau khi nguoi dung bam Luu: `Navigator.pop()` tra ve text moi, UI hien dialog cho loading, `provider.updateComment()` duoc goi.
- Provider chi cap nhat noi dung comment trong cache - khong can reload toan bo trang.
- Khi thanh cong: snackbar "Da cap nhat binh luan".

### 3.4 Xoa binh luan

- `_confirmDeleteComment` dung `UIHelpers.showConfirmDialog` voi nut confirm mau do.
- Neu dong y: show loading dialog, `provider.deleteComment(comment.id)`.
- Provider loai bo item va giam `total` (neu >0). UI thong bao "Da xoa binh luan".

### 3.5 Trang thai va loi thong dung

- `BinhLuanProvider.error` duoc doc sau moi thao tac. Neu khong null, UI show snackbar `showErrorSnackBar`.
- Loi validation (tu backend) bi map sang thong diep "Noi dung binh luan khong hop le (toi thieu 5, toi da 500 ky tu)".
- Tat ca snackbar su dung `UIHelpers` de dam bao style dong nhat.

## 4. Logic Provider & Service

### 4.1 `BinhLuanProvider`

- Luu `PaginatedResponse<BinhLuan>? comments`, `bool isLoading`, `String? error`.
- Moi thao tac set `_isLoading = true` truoc khi goi service va `notifyListeners()` de UI update spinner.
- `createComment` chen comment moi vao dau danh sach ton tai, tang `total`. Neu chua co du lieu, tao `PaginatedResponse` moi voi page = 1, pageSize = 20.
- `updateComment` map qua `items` va thay the noi dung. `deleteComment` filter bo id va giam `total` neu >0.
- `clearComments()` reset state, goi khi dang xuat hoac doi de thi trong provider khac.

### 4.2 `BinhLuanService`

- `fetchByDeThi` goi `ApiClient.get` voi query page/pageSize. Response duoc kiem tra la `Map<String, dynamic>`; neu khong, nem `ApiException` voi message huu ich.
- `createBinhLuan` post JSON body `{'deThiId': deThiId, 'noiDung': noiDung}`. Response phai la map, duoc map sang `BinhLuan.fromJson`.
- `updateBinhLuan` va `deleteBinhLuan` khong tra data; loi status code duoc `ApiClient` convert sang `ApiException`.

## 5. Backend API & bao mat

- `GET /api/BinhLuan/dethi/{deThiId}`: `[AllowAnonymous]`. Phan trang (page >=1, pageSize clamp 1..100), sap xep `NgayTao` giam dan. Tra `total` + `items` gom author basic info (`Id`, `UserName`, `FullName`, `AvatarUrl`).
- `POST /api/BinhLuan`: `[Authorize]`. Trim noi dung, `[StringLength(500, MinimumLength = 5)]` tren request DTO. Tra `201 Created` voi object co `Id`, `NoiDung`, `NgayTao`, `DeThiId`.
- `PUT /api/BinhLuan/{id}`: `[Authorize]`. Chi cho phep chu so huu (so sanh `TaiKhoanId`) sua. Tra `204 NoContent`.
- `DELETE /api/BinhLuan/{id}`: `[Authorize]`. Chu so huu hoac role Admin moi xoa. Tra `204 NoContent`.

## 6. Tinh huong loi & canh giac

- `Unauthorized (401)`: xay ra khi nguoi dung chua dang nhap ma gui/sua/xoa. UI hien snackbar tu `provider.error`. Nen xem xet chuyen huong sang man hinh dang nhap neu gap thuong xuyen.
- `ValidationProblem`: backend tra message chua chi tiet. Provider gan `error = e.message`; `_submitComment` map sang thong diep thoai mai truoc khi show.
- `Forbidden (403)`: xay ra khi thu sua/xoa comment cua nguoi khac. UI thong bao loi chung tu provider.
- Network gap: `fetchComments` bat ky exception -> message `Co loi xay ra: ...`. Nen them thong diep than thien neu muon.

## 7. Goi y kiem thu

| Test | Cong cu | Muc tieu |
|------|---------|----------|
| Fetch comments happy path | Unit test provider voi mock `BinhLuanService` | Dam bao set loading, populate `comments`, reset error |
| Create comment validation | Widget test `_submitComment` voi TextEditingController | Kiem tra thong diep 5 ky tu va 500 ky tu |
| Create comment API error | Mock service nem `ApiException('Validation failed')` | Provider luu error, UI show snackbar friendlier |
| Update comment owner only | Integration test backend voi user B (khong phai author) | Ky vong 403 |
| Delete comment reduces total | Provider unit test | Sau delete, `total` giam 1 va item bien mat |
| RefreshIndicator | Widget test keo tren ListView | Kiem tra `fetchComments` bi goi lai |

## 8. Ghi chu bo sung

- Khong co giao dien quan tri rieng cho binh luan. Admin chi co the xoa thong qua API (hoac thong qua ung dung neu dang nhap voi role Admin).
- `BinhLuanProvider` su dung chung bo nho `_isLoading` cho tat ca thao tac. Neu can phan biet (vi du, show spinner rieng cho submit), co the tach thanh co flag rieng.
- Nen can nhac cache hoac phan trang vo han neu danh sach binh luan lon (service hien tai load theo page, UI moi lan keo chi goi page 1).
- Khi doi de thi, goi `BinhLuanProvider.clearComments()` de tranh hien thi comment cu.
