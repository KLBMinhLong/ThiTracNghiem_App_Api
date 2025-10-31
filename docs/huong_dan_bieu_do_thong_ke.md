# CHART THONG KE KET QUA THI - TAI LIEU CHI TIET

## 1. Tong quan luong hoat dong

```
HomeScreen (Profile tab) ListTile "Thong ke ket qua"
  -> Navigator.push StatisticsScreen
  -> StatisticsScreen.didChangeDependencies() goi _load()
  -> _load():
       context.read<KetQuaThiProvider>().fetchKetQuaThiList(onlyUserId: currentUser.id)
       context.read<ChuDeProvider>().fetchChuDes()
  -> Provider cap nhat ket qua va danh sach chu de -> notifyListeners
  -> Consumer<KetQuaThiProvider> render danh sach KPI + chart
```

## 2. Thanh phan va vi tri ma nguon

| Thanh phan | Mo ta | File lien quan |
|------------|-------|----------------|
| Man thong ke | UI KPI, line chart, bar chart | `lib/screens/statistics_screen.dart` |
| KPI cards | Tong bai thi, diem trung binh, diem cao nhat | `_SummaryCard` trong `statistics_screen.dart` |
| Line chart | Diem theo thoi gian | `_ScoreOverTimeCard` trong `statistics_screen.dart` |
| Bar chart | Diem trung binh theo chu de | `_AverageByTopicCard` trong `statistics_screen.dart` |
| Provider ket qua | Lay danh sach KetQuaThi, bo loc user | `lib/providers/ket_qua_thi_provider.dart` |
| Service ket qua | REST `/api/KetQuaThi` | `lib/services/ket_qua_thi_service.dart` |
| Model KetQuaThi | Parse summary + detail | `lib/models/ket_qua_thi.dart` |
| Provider chu de | Cach lay ten chu de cho chart | `lib/providers/chu_de_provider.dart` |
| API backend | Danh sach ket qua co embed chu de | `ThiTracNghiemApi/Controllers/KetQuaThiController.cs` |
| Thu vien chart | `fl_chart` (pubspec: `fl_chart: ^0.69.0`) | `thitracnghiemapp/pubspec.yaml` |

> So lieu trong tai lieu duoc tham chieu tai commit ngay 31/10/2025.

## 3. Trinh bay giao dien & hanh vi

### 3.1 KPI cards (`_SummaryCard`)

- Su dung `Row` 3 cot, moi card goi `_SummaryCard`.
- Gia tri tinh toan:
  - Tong bai thi = so luong `KetQuaThiSummary` co diem khac null.
  - Diem trung binh = tong diem / so phan tu, lam tron `toStringAsFixed(1)`.
  - Diem cao nhat = `reduce(max)` tren mang diem.
- Ve UI: gradient nho cho icon, border, shadow nhe, mau linh hoat qua tham so `color`.
- Khi danh sach rong, `_buildEmpty()` thay the KPI bang thong diep "Chua co du lieu thong ke".

### 3.2 Line chart diem theo thoi gian (`_ScoreOverTimeCard`)

- Du lieu chuan bi:
  - Sao chep danh sach `items`, sap xep tang dan theo `ngayThi`.
  - Tao `FlSpot` voi x = chi so (double), y = diem (mac dinh 0 neu null).
  - `maxScore` la gia tri lon nhat clamp 0..10 de dat `maxY` (toi thieu 10 hoac max + 1).
- Cau hinh chart:
  - `LineChartData` voi `minY = 0`, `maxY = max(10, maxScore + 1)`.
  - Grid ngang moi 2 diem, khong ve grid doc.
  - Border: chi trai va duoi, top/right transparent.
  - Tieu de truc X: dinh dang `dd/MM` theo vi tri spot, `interval = (sorted.length / 6).clamp(1, 6)` de giam bot label khi nhieu diem.
  - Truc Y: hien so nguyen cach 2 diem.
  - `LineChartBarData`: duong cong `isCurved = true`, `curveSmoothness = 0.35`, duong mau theme primary, dot circle radius 4, area gradient tu 15% -> 0% opacity.

### 3.3 Bar chart diem trung binh theo chu de (`_AverageByTopicCard`)

- Lay danh sach chu de tu `ChuDeProvider.chuDes` (da fetch trong `_load`).
- Ham `topicNameFor`:
  1. Uu tien `e.deThi?.chuDe?.tenChuDe` neu co.
  2. Neu khong, tim trong list `chuDes` theo `chuDeId`.
  3. Fallback "Khac".
- Gom diem theo topic: `Map<String, List<double>>` -> compute average = tong / count.
- Sap xep giam dan theo diem trung binh, gioi han `take(8)` de tranh dong nat.
- Neu khong co topic -> card thong bao "Chua co du lieu theo chu de".
- Chart config:
  - `BarChartAlignment.spaceAround`, `maxY = 10`.
  - Grid ngang 2 diem, border trai/duoi.
  - Truc trai (Y) hien so 0..10 buoc 2.
  - Truc tren hien so diem trung binh (1 chu so thap phan) tren moi cot.
  - Truc duoi (X) hien ten chu de (toi da 2 dong, ellipsis neu dai).
  - Moi `BarChartGroupData` co mot `BarChartRodData` gradient primary -> secondary, width 18, bo goc tren 6.

### 3.4 Refresh & empty state

- `RefreshIndicator` goi `_load()` de refetch ca ket qua va chu de.
- Neu provider dang loading va chua co data -> spinner.
- Neu khong loading nhung list rong -> `_buildEmpty()`.
- Khi co du lieu -> render KPI + chart theo thu tu: Summary -> Line -> Bar.

## 4. Tang du lieu & provider

### 4.1 `KetQuaThiProvider.fetchKetQuaThiList`

- Goi `KetQuaThiService.fetchKetQuaThis(page: 1)` (page size mac dinh 10).
- Sau khi nhan response:
  - Neu `onlyUserId` khac null -> filter `items` de chi giu record cua user (so sanh `taiKhoan?.id ?? taiKhoanId`).
  - Cap nhat `_ketQuaThiList` bang `copyWith`, `total` = so item sau filter.
- Quan ly `_isLoading`, `_error` de UI biet trang thai.

### 4.2 `KetQuaThiService.fetchKetQuaThis`

- GET `/api/KetQuaThi?page={page}&pageSize={pageSize}`.
- Kiem tra response la `Map<String, dynamic>`; neu khong -> `ApiException` voi thong diep "Khong lay duoc danh sach ket qua".
- Parse `items` -> `KetQuaThiSummary.fromJson` (co embed de thi, chu de, tai khoan, diem).

### 4.3 `ChuDeProvider.fetchChuDes`

- GET `/api/ChuDe` (qua service) -> luu vao `_chuDes`.
- Duoc dung trong bar chart de giai ma ten chu de, bao gom cac chu de duoc create boi admin.

## 5. Backend API lien quan

- `GET /api/KetQuaThi` (yeu cau auth):
  - Admin: nhan toan bo record, embed thong tin user.
  - User thuong: filter `TaiKhoanId == currentUser`.
  - Include `DeThi` + `ChuDe` de UI co du lieu topic.
  - Sap xep `NgayThi` giam dan (UI tu sap xep lai tang dan cho line chart).
  - Ho tro `page` (>=1) va `pageSize` (1..50).

> Khong co endpoint rieng cho thong ke; UI tu tinh toan tu danh sach KetQuaThi.

## 6. Xu ly loi & tinh huong can luu y

- `KetQuaThiProvider.error` duoc doc trong UI: neu khong null va list rong -> can hien snackbar tu `_load()` (co the them neu can).
- Khi API tra ve so luong > page size mac dinh (10), line chart se chi hien du lieu cua page dau tien. Neu muon phan tich day du can tang `pageSize` hoac implement infinite scroll.
- Neu user chua co KetQuaThi => `_buildEmpty()` hien thong diep khac.
- Bar chart gioi han 8 topic; neu co nhieu hon -> chi top 8 duoc hien thi.
- `fl_chart` tao widget nang, nen tranh bao nghiep UI tren thiet bi cu neu dataset lon.

## 7. Goi y kiem thu

| Test | Cong cu | Muc tieu |
|------|---------|----------|
| Provider fetch + filter | Unit test `KetQuaThiProvider` voi mock service | Dam bao chi tra ve record cua currentUser, `_isLoading` va `_error` duoc dat dung |
| Line chart du lieu tang dan | Widget test `_ScoreOverTimeCard` voi dataset sap xep nguoc | Kiem tra `FlSpot` thu tu tang dan theo ngay |
| Bar chart top 8 | Unit/widget test voi >8 topic | Dam bao chi hien 8 topic va thu tu giam dan theo diem TB |
| Empty state | Widget test voi danh sach rong | Xac nhan `_buildEmpty()` render dung thong diep |
| RefreshIndicator | Widget test keo xuong | Kiem tra `_load()` duoc goi lai (co the dung mock `KetQuaThiProvider`) |

## 8. Ghi chu implement

- Neu muon mo rong bieu do cho admin (nhieu user), can them bo loc theo user/chu de va tang page size.
- Nhanh load hon neu service ho tro query theo user: hien tai filter thuc hien tren client.
- Can dam bao `KetQuaThiSummary.diem` khong null truoc khi add vao chart. Hien tai code bo qua record null (items = where `diem != null`).
- Khi thay doi API response (vi du doi property `NgayThi`), can cap nhat `KetQuaThiSummary.fromJson` de tranh crash line chart.
- `fl_chart` can khoi tao trong `SizedBox` co chieu cao xac dinh; neu UI nested trong `SingleChildScrollView`, luon dat `shrinkWrap` hoac `SizedBox` nhu hien tai.
