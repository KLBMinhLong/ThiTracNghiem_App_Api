# Thi Trac Nghiem App & API

Tai lieu nay giai thich cach cai dat va chay du an thi trac nghiem gom API (ASP.NET Core) va ung dung Flutter.

## Tong quan
- Thu muc `ThiTracNghiemApi/`: API .NET 9 cung cap cac dich vu dang nhap, quan ly de thi, lam bai thi, binh luan.
- Thu muc `thitracnghiemapp/`: Ung dung Flutter cho nguoi dung va quan tri, ho tro Android, iOS, Web, Desktop.

## Cau truc thu muc chinh
```
ThiTracNghiem_App_Api/
├─ ThiTracNghiemApi/        # Ma nguon API ASP.NET Core
├─ thitracnghiemapp/        # Ma nguon ung dung Flutter
└─ README.md                # Tai lieu huong dan
```

## Yeu cau he thong
- .NET SDK 9.0 tro len
- SQL Server (Developer hoac Express)
- Flutter SDK 3.22+ va Dart 3.4+
- Node.js (tuy chon neu build web va can tooling bo sung)

## Cai dat API (ThiTracNghiemApi)
1. Chinh sua file `ThiTracNghiemApi/appsettings.Development.json` de cap nhat `ConnectionStrings:DefaultConnection` phu hop voi SQL Server cua ban.
2. Khoi tao co so du lieu:
   ```powershell
   cd ThiTracNghiemApi
   dotnet tool restore
   dotnet ef database update
   ```
   > Neu chua cai `dotnet-ef` thi chay `dotnet tool install --global dotnet-ef`.
3. Chay API o che do Development:
   ```powershell
   dotnet run
   ```
   - API mac dinh lang nghe tai `http://localhost:5103` (theo `launchSettings.json`).
   - Swagger UI co san tai `http://localhost:5103/index.html`.
4. (Tuy chon) Tao nguoi dung admin dau tien bang cach goi endpoint dang ky va cap quyen, hoac chen truc tiep trong DB.

## Cai dat ung dung Flutter (thitracnghiemapp)
1. Tao file moi `thitracnghiemapp/.env` (co the copy tu `.env.example`):
   ```
   BASE_URL=http://localhost:5103
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```
   - `BASE_URL`: khong co dau `/` cuoi.
   - `GOOGLE_CLIENT_ID`: phai la Web Client ID (Google OAuth), ket thuc bang `.apps.googleusercontent.com`.
2. Khoi phuc cac file bi bo qua (generated/ephemeral):
   - Chay cac lenh sau de Flutter tu dong sinh file thieu (`.dart_tool`, `.flutter-plugins*`, `generated_plugin_registrant.dart`, Pods, ...).
   ```powershell
   cd thitracnghiemapp
   flutter clean ; flutter pub get
   # (Tuy chon neu dung codegen) dart run build_runner build --delete-conflicting-outputs
   ```
   - Android: file `android/local.properties` se duoc tao boi Android tooling. Neu chua co, mo project bang Android Studio mot lan hoac tu tao file voi `sdk.dir` tro den thu muc Android SDK.
3. Chay ung dung:
   ```powershell
   flutter run
   ```
   - Mac dinh Flutter se hoi chon thiet bi (Chrome, Android emulator, Windows, ...).
   - Dam bao API dang chay truoc khi dang nhap hoac lay de thi.
4. Build cac nen khac (vi du):
   ```powershell
   flutter build apk        # Android
   flutter build web        # Web
   flutter build windows    # Windows Desktop
   ```

## Bien moi truong & file bi bo qua
- `.env` (Flutter) va `appsettings*.json` (API) khong duoc commit theo `.gitignore`.
- Da kem san: `thitracnghiemapp/.env.example` va `ThiTracNghiemApi/appsettings.Development.example.json` de ban sao chep.

### Ghi chu Google Sign-In (Android)
- Trong Google Cloud Console, tao 2 OAuth client:
   1) Web application (dung de xac thuc voi server) — su dung lam `GOOGLE_CLIENT_ID` trong `.env`.
   2) Android application (package: `com.example.thitracnghiemapp`, SHA-1 debug) — giup app Android dang nhap thanh cong.
- Neu gap loi `ApiException: 10` khi dang nhap Google, kiem tra lai package name, SHA-1 va client ID.

### Ghi chu Windows Desktop
- Bat Developer Mode de cho phep symlink (yeu cau cho mot so plugin): Settings → For developers → Developer Mode.
- Cai Visual Studio workload “Desktop development with C++” (MSVC, CMake, Windows 10/11 SDK) de build Windows.

## Lenh huu ich
| Tac vu                        | Lenh |
|------------------------------|------|
| Format code Flutter          | `flutter format lib` |
| Chay test Flutter            | `flutter test` |
| Chay test API (.NET)         | `dotnet test` |
| Tao migration moi            | `dotnet ef migrations add <Ten>` |
| Lan doc Migration            | `dotnet ef database update` |

## Dong gop
1. Fork hoac tao nhanh moi: `git checkout -b feature/<ten>`.
2. Thuc hien thay doi, chay test.
3. Mo pull request mo ta ro muc dich.