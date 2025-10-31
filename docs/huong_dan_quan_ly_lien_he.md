# LIEN HE/GOP Y: NGUOI DUNG GUI & QUAN TRI VIEN XU LY

## 1. Tom tat luong

```
HomeScreen._loadInitialData()
  -> LienHeProvider.fetchMine()
  -> LienHeService.fetchMyLienHes()
  -> GET /api/LienHe/mine (LienHeController.GetMyLienHes)
  -> LienHeProvider.myLienHe duoc cap nhat sap xep moi nhat

Nguoi dung nhan "Gui gop y"
  -> _ContactTab._showEditContact(isCreate: true)
  -> Dien form tieu de + noi dung
  -> LienHeProvider.createLienHe()
  -> LienHeService.createLienHe()
  -> POST /api/LienHe (LienHeController.CreateLienHe)
  -> Provider chen ban ghi moi vao bo nho cache

Chinh sua lien he da gui
  -> PopupMenu "Chinh sua" -> _showEditContact(contact)
  -> LienHeProvider.updateLienHe()
  -> PUT /api/LienHe/{id} (LienHeController.UpdateLienHe)
  -> Cap nhat item trong danh sach hien tai

Xoa lien he
  -> Dismissible onDismissed / PopupMenu "Xoa"
  -> LienHeProvider.deleteLienHe()
  -> DELETE /api/LienHe/{id} (LienHeController.DeleteLienHe)
  -> Provider loc bo item + giam dem total

---

AdminDashboardScreen._loadInitialData()
  -> LienHeProvider.fetchAll(page)
  -> LienHeService.fetchLienHes()
  -> GET /api/LienHe?page=... (LienHeController.GetLienHes)
  -> Tra ve danh sach phan trang kem thong tin tai khoan

Admin xem chi tiet gop y
  -> InkWell ContactCard -> _showContactDetailDialog()
  -> Hien dialog voi thong tin nguoi gui, email, ngay gui, noi dung

Admin xoa gop y
  -> IconButton.delete -> _deleteContact()
  -> LienHeProvider.deleteLienHe()
  -> DELETE /api/LienHe/{id}
  -> Goi lai fetchAll de dong bo state
```

## 2. Thanh phan tham gia & vi tri ma nguon

| Buoc | Mo ta | File lien quan |
|------|-------|----------------|
| Khoi tao tab nguoi dung | Day cac provider can thiet (thi, chu de, lien he) | `lib/screens/home_screen.dart` (`HomeScreen._loadInitialData`) |
| Tab lien he nguoi dung | UI list ca nhan, RefreshIndicator, swipe xoa, menu chinh sua | `lib/screens/home_screen.dart` (`_ContactTab`) |
| Bottom sheet gui/chinh sua | Form validator, max length, goi provider tu nut luu | `lib/screens/home_screen.dart` (`_showEditContact`) |
| Provider lien he | Giu cache `_myLienHe`, `_allLienHe`, quan ly loading/error, cap nhat local sau CRUD | `lib/providers/lien_he_provider.dart` |
| Service lien he | Wrap API `/api/LienHe` (GET mine/all, POST, PUT, DELETE) | `lib/services/lien_he_service.dart` |
| Admin contacts section | Card danh sach, dialog chi tiet, phan trang, xoa | `lib/screens/admin/admin_dashboard_screen.dart` (`_buildContactsSection`) |
| API backend | Endpoint GET mine, GET (admin), POST, PUT, DELETE + kiem tra quyen | `ThiTracNghiemApi/Controllers/LienHeController.cs` |
| DTO validate | Gioi han tieu de <= 200 ky tu, noi dung <= 2000 ky tu | `ThiTracNghiemApi/Dtos/LienHe/CreateLienHeRequest.cs`, `ThiTracNghiemApi/Dtos/LienHe/UpdateLienHeRequest.cs` |

> Thong tin tham chieu tai thoi diem 31/10/2025. Neu thay doi, tim theo ten ham duoc liet ke.

## 3. Luong gui gop y tu nguoi dung

### 3.1 Nap danh sach ca nhan

- `HomeScreen._loadInitialData` goi `context.read<LienHeProvider>().fetchMine()` ngay sau khi xac thuc thanh cong.
- `LienHeProvider.fetchMine` bat co loading, xoa loi, sau do goi `LienHeService.fetchMyLienHes`.
- Service thuc hien `GET /api/LienHe/mine`; controller xac dinh user tu JWT (`User.ResolveUserIdAsync`) va tra ve danh sach sap xep `NgayGui` giam dan.
- Provider cap nhat `_myLienHe` va thong bao UI; `_ContactTab` render `RefreshIndicator` + `ListView` hoac Empty/Error state.

### 3.2 Gui gop y moi

- Nut `FilledButton.icon` "Gui gop y" se disable khi `LienHeProvider.isLoading` dang true.
- Khi nhan, `_showEditContact()` mo `showModalBottomSheet` chua `Form` voi 2 `TextFormField` (tieu de, noi dung) va maxLength (200/2000).
- Nhan "Luu" -> form validate, goi `await provider.createLienHe(...)`.
- Provider goi `_service.createLienHe` (POST). Backend tao `LienHe` voi `NgayGui = DateTime.UtcNow`, `TaiKhoanId` tu token, sau do `CreatedAtAction` tra JSON item moi.
- Provider chen item moi len dau `_myLienHe`; neu `_allLienHe` ton tai (dang o tab admin) thi cung cap nhat de dong bo cache.
- Sheet dong va `_showEditContact` hien `SnackBar` thong bao thanh cong.

### 3.3 Chinh sua & xoa

- Moi card co `PopupMenuButton` voi "Chinh sua" va "Xoa". `Dismissible` cung goi xoa khi vuot sang trai.
- Chinh sua: `_showEditContact(contact)` prefill du lieu, submit -> `LienHeProvider.updateLienHe`.
  - Provider set loading, goi `_service.updateLienHe` (PUT). Backend kiem tra `ModelState`, tim ban ghi, chi cho phep chu so huu (`TaiKhoanId`) hoac admin.
  - Khi thanh cong, provider thay the item trong `_myLienHe` va `_allLienHe` bang instance moi.
- Xoa: `UIHelpers.showConfirmDialog` hoi lai, confirm -> `LienHeProvider.deleteLienHe(id)`.
  - Provider set loading, goi `_service.deleteLienHe` (DELETE). Backend xac thuc chu so huu/admin, `NoContent` neu hop le.
  - `_myLienHe` va `_allLienHe` loc bo item, `total` giam neu >0. UI hien `SnackBar` thong bao.
- `RefreshIndicator` tren tab cho reload chu dong neu muon dong bo lai voi server.

### 3.4 Xu ly trang thai UI

- Khi `isLoading` true va `_myLienHe` null -> `_ContactTab` hien `CircularProgressIndicator`.
- Neu `error` ton tai -> `ErrorState` voi nut "Thu lai" goi `fetchMine()`.
- Khi danh sach rong -> `EmptyState` nho nguoi dung gui gop y dau tien.

## 4. Luong quan tri vien xu ly gop y

### 4.1 Tai danh sach toan bo

- `AdminDashboardScreen._loadInitialData` goi `context.read<LienHeProvider>().fetchAll()` khi vao tab lien he.
- `LienHeProvider.fetchAll` goi `_service.fetchLienHes(page: page)` va luu ket qua vao `PaginatedResponse<LienHe>`.
- Service goi `GET /api/LienHe?page=...&pageSize=...`; controller chi cho phep role Admin, `Include(TaiKhoan)` de lay `FullName`, `UserName`, `Email`.
- Provider thong bao UI, `_buildContactsSection` hien so luong tong qua `infoBadge` tren header.

### 4.2 Xem chi tiet

- Tap vao card -> `_showContactDetailDialog(contact)`.
- Dialog gom avatar placeholder, ten nguoi gui (fullname, username, fallback "Nguoi dung da xoa"), email `SelectableText`, ngay gui dinh dang tu `UIHelpers.formatDateTime`, noi dung `SelectableText` de sao chep.
- Nut "Dong" dong dialog, khong goi API.

### 4.3 Xoa gop y

- Icon thung rac -> `_deleteContact(contact)` hoi xac nhan.
- Confirm -> `await provider.deleteLienHe(contact.id)`.
- Neu success -> `ScaffoldMessenger.of(context).showSnackBar('Da xoa gop y')` va `await provider.fetchAll()` de tai lai trang hien tai.
- Xu ly truong hop ton tai `_contactPage > 1` va danh sach trong -> co the goi lai fetchAll voi page truoc (logic nay dang duoc quan ly trong setState sau khi fetch).

### 4.4 Phan trang & loading

- `_buildContactsSection` hien `PaginationControls` duoc chia se giua cac tab admin; chon page moi -> cap nhat `_contactPage` va goi `fetchAll(page: page)`.
- Trong qua trinh load -> container giua man hinh hien `CircularProgressIndicator`.
- Neu `_allLienHe?.items` rong va khong loading -> hien `EmptyState` thong bao khong co gop y nao.

## 5. Quy tac backend & bao mat

- DTO `CreateLienHeRequest`/`UpdateLienHeRequest` bat buoc tieu de va noi dung, gioi han 200/2000 ky tu, tra 400/422 neu vi pham.
- `CreateLienHe` chi chap nhan user dang dang nhap, tu dong gan `TaiKhoanId` theo token.
- `UpdateLienHe` va `DeleteLienHe` chi cho phep chu so huu hoac admin (`User.IsInRole("Admin")`), tra 403 neu khong hop le.
- `GetLienHes` phai la admin; `GetMyLienHes` phai dang nhap.
- Tat ca query su dung `AsNoTracking` de han che chi phi tracking khi chi doc du lieu.

## 6. Kiem thu va ghi chu thong dung

- Thu gui gop y voi chuoi vuot qua max length de dam bao validator UI bat loi truoc khi hit API.
- Mo tab admin o hai thiet bi -> sau khi xoa o mot ben, dung `RefreshIndicator` hoac `fetchAll` de dong bo may con lai.
- Khi thay doi quyen (dang xuat/dang nhap lai), nho goi `LienHeProvider.clear()` de xoa cache cu.

## 7. Thanh phan lien quan khac

- Model `LienHe` (`lib/models/lien_he.dart`) dinh nghia `fromJson`, `toJson`, `copyWith` phuc vu provider.
- `UIHelpers.showConfirmDialog` (`lib/utils/ui_helpers.dart`) duoc dung cho confirm xoa tren ca user va admin.
- `ApiClient` quan ly bearer token, tu dong refresh khi nhan 401, nen cac service khong can lap lai logic nay.
