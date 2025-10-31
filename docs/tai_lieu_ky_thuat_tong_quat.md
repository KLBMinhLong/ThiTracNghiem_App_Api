# HỆ THỐNG THI TRẮC NGHIỆM - TECHNICAL DOCUMENTATION

## 📋 TỔNG QUAN Dự ÁN

**Tên dự án**: Smart Test - Hệ thống thi trắc nghiệm thông minh  
**Kiến trúc**: Client-Server (Flutter Mobile App + ASP.NET Core Web API)  
**Mục đích**: Quản lý và thực hiện các bài thi trắc nghiệm trực tuyến

---

## 🏗️ KIẾN TRÚC TỔNG THỂ

### 1. Backend - ThiTracNghiemApi (.NET 9.0)
- **Framework**: ASP.NET Core Web API
- **Database**: SQL Server (Entity Framework Core)
- **Authentication**: JWT Bearer Token + Google OAuth2
- **Architecture Pattern**: MVC với Repository Pattern

### 2. Frontend - thitracnghiemapp (Flutter)
- **Framework**: Flutter (Dart)
- **State Management**: Provider Pattern
- **UI Framework**: Material Design 3
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux

---

## 📂 CẤU TRÚC THƯ MỤC CHI TIẾT

### BACKEND STRUCTURE

```
ThiTracNghiemApi/
│
├── Controllers/              # API Endpoints
│   ├── AuthController.cs    # Đăng nhập, đăng ký, 2FA, forgot password
│   ├── UsersController.cs   # Quản lý người dùng (Admin)
│   ├── ChuDeController.cs   # CRUD chủ đề
│   ├── CauHoiController.cs  # CRUD câu hỏi, import Excel
│   ├── DeThiController.cs   # CRUD đề thi
│   ├── ThiController.cs     # Thực hiện bài thi
│   ├── KetQuaThiController.cs # Xem kết quả thi
│   ├── BinhLuanController.cs  # Comment hệ thống
│   ├── ChatController.cs      # Chat real-time (planned)
│   └── LienHeController.cs    # Liên hệ/Feedback
│
├── Models/                   # Database Entities
│   ├── ApplicationUser.cs   # User (kế thừa IdentityUser)
│   ├── ChuDe.cs            # Topic/Category
│   ├── CauHoi.cs           # Question
│   ├── DeThi.cs            # Exam
│   ├── KetQuaThi.cs        # Exam Result
│   ├── ChiTietKetQuaThi.cs # Result Detail (per question)
│   ├── BinhLuan.cs         # Comment
│   └── LienHe.cs           # Contact Message
│
├── Dtos/                    # Data Transfer Objects
│   ├── Auth/               # Login, Register, Reset Password
│   ├── Users/              # User Management DTOs
│   ├── CauHoi/             # Question DTOs, Import
│   ├── Thi/                # Exam Submission DTOs
│   ├── BinhLuan/           # Comment DTOs
│   ├── Chat/               # Chat Message DTOs
│   └── LienHe/             # Contact DTOs
│
├── Data/
│   └── ApplicationDbContext.cs  # EF Core DbContext
│
├── Services/
│   ├── IEmailSender.cs     # Email Service Interface
│   └── SmtpEmailSender.cs  # SMTP Email Implementation
│
├── Extensions/
│   ├── ClaimsPrincipalExtensions.cs  # Get User ID from Claims
│   └── UserMappingExtensions.cs      # Entity to DTO mapping
│
├── Options/
│   └── SmtpOptions.cs      # Email Configuration
│
├── Migrations/             # EF Core Migrations
│   └── [Migration Files]
│
├── appsettings.json        # App Configuration
├── appsettings.Development.json  # Dev Configuration
└── Program.cs              # Application Entry Point
```

### FRONTEND STRUCTURE

```
thitracnghiemapp/
│
├── lib/
│   ├── main.dart           # App Entry Point
│   │
│   ├── core/               # Core Utilities
│   │   ├── api_client.dart      # HTTP Client Wrapper
│   │   ├── api_exception.dart   # Custom Exceptions
│   │   ├── token_storage.dart   # Secure Token Storage
│   │   └── app_env.dart         # Environment Variables
│   │
│   ├── models/             # Data Models (Mirror Backend)
│   │   ├── user.dart
│   │   ├── chu_de.dart
│   │   ├── cau_hoi.dart
│   │   ├── de_thi.dart
│   │   ├── ket_qua_thi.dart
│   │   ├── binh_luan.dart
│   │   ├── lien_he.dart
│   │   ├── auth_response.dart
│   │   └── two_fa.dart
│   │
│   ├── providers/          # State Management (Provider Pattern)
│   │   ├── auth_provider.dart        # Authentication State
│   │   ├── users_provider.dart       # User Management
│   │   ├── chu_de_provider.dart      # Topics
│   │   ├── cau_hoi_provider.dart     # Questions
│   │   ├── de_thi_provider.dart      # Exams
│   │   ├── thi_provider.dart         # Take Exam State
│   │   ├── ket_qua_thi_provider.dart # Results
│   │   ├── binh_luan_provider.dart   # Comments
│   │   ├── chat_provider.dart        # Chat
│   │   └── lien_he_provider.dart     # Contact
│   │
│   ├── services/           # API Service Layer
│   │   ├── auth_service.dart
│   │   ├── users_service.dart
│   │   ├── chu_de_service.dart
│   │   ├── cau_hoi_service.dart
│   │   ├── de_thi_service.dart
│   │   ├── thi_service.dart
│   │   ├── ket_qua_thi_service.dart
│   │   ├── binh_luan_service.dart
│   │   ├── chat_service.dart
│   │   └── lien_he_service.dart
│   │
│   ├── screens/            # UI Screens
│   │   ├── splash_screen.dart          # Splash Screen
│   │   ├── login_screen.dart           # Login
│   │   ├── register_screen.dart        # Register
│   │   ├── forgot_password_screen.dart # Forgot Password
│   │   ├── two_fa_login_screen.dart    # 2FA Verification
│   │   ├── home_screen.dart            # Main Dashboard
│   │   ├── quiz_screen.dart            # Take Exam
│   │   ├── result_screen.dart          # View Result
│   │   ├── profile_screen.dart         # User Profile
│   │   ├── contact_screen.dart         # Contact Form
│   │   └── admin/
│   │       └── admin_dashboard_screen.dart  # Admin Panel
│   │
│   ├── themes/
│   │   └── app_theme.dart  # Material Design Theme
│   │
│   └── utils/
│       └── ui_helpers.dart # UI Constants & Helpers
│
├── assets/                 # Static Assets
│   ├── quizlogo.png       # App Logo
│   ├── Splash_Screen.png  # Splash Image
│   └── app_icon.png       # App Icon
│
├── android/               # Android Native Code
├── ios/                   # iOS Native Code
├── web/                   # Web Configuration
├── windows/               # Windows Native Code
├── linux/                 # Linux Native Code
├── macos/                 # macOS Native Code
│
├── .env                   # Environment Variables (API URL, etc.)
├── pubspec.yaml           # Dependencies & Assets
└── README.md
```

---

## 🔄 LUỒNG HOẠT ĐỘNG CHI TIẾT

### 1. KHỞI ĐỘNG ỨNG DỤNG

```
┌─────────────────────────────────────────────────────────┐
│ 1. App Start (main.dart)                                │
│    - Load .env configuration                            │
│    - Initialize ApiClient with BASE_URL                 │
│    - Initialize TokenStorage                            │
│    - Create Provider instances                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Splash Screen Display                                │
│    - Show Splash_Screen.png                             │
│    - CircularProgressIndicator                          │
│    - "Đang tải ứng dụng..."                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 3. AuthProvider.initialize()                            │
│    - Read stored JWT token from TokenStorage            │
│    - Check if token exists and not expired             │
│    - If valid: Fetch fresh user profile from API       │
│    - If invalid: Clear storage                         │
│    - Minimum 2s delay for splash screen                │
│    - Set isInitialized = true                          │
└─────────────────────────────────────────────────────────┘
                          ↓
                  ┌───────┴───────┐
                  │               │
            Token Valid?    Token Invalid/Expired
                  │               │
                  ↓               ↓
         ┌─────────────┐  ┌──────────────┐
         │ Home Screen │  │ Login Screen │
         └─────────────┘  └──────────────┘
```

### 2. LUỒNG ĐĂNG NHẬP (AUTHENTICATION FLOW)

#### A. Đăng nhập thường (Username/Password)

```
User Input Credentials
         ↓
┌─────────────────────────────────────────┐
│ 1. LoginScreen                          │
│    - Validate form (username, password) │
│    - Call AuthProvider.login()          │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. AuthProvider.login()                 │
│    - Call AuthService.loginRaw()        │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. AuthService → API POST /auth/login  │
│    Body: { identifier, password }      │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend: AuthController.Login()     │
│    - Find user by username/email        │
│    - Verify password                    │
│    - Check if 2FA enabled              │
└─────────────────────────────────────────┘
         ↓
    ┌────┴────┐
    │         │
2FA ON?    2FA OFF
    │         │
    ↓         ↓
┌─────────┐  ┌──────────────────────┐
│ Return  │  │ Generate JWT Token   │
│ { req-  │  │ Return AuthResponse: │
│ uires   │  │ - token              │
│ TwoF-   │  │ - user               │
│ actor:  │  │ - expiresAt          │
│ true,   │  └──────────────────────┘
│ userId  │            ↓
│ }       │  ┌──────────────────────┐
└─────────┘  │ 5. Client Receives   │
    ↓        │    - Save token to   │
┌─────────┐  │      TokenStorage    │
│Navigate │  │    - Set currentUser │
│to 2FA   │  │    - Navigate to     │
│Screen   │  │      HomeScreen      │
└─────────┘  └──────────────────────┘
```

#### B. Đăng nhập Google OAuth

```
User Taps "Đăng nhập với Google"
         ↓
┌─────────────────────────────────────────┐
│ 1. LoginScreen._loginWithGoogle()      │
│    - Initialize GoogleSignIn            │
│    - Sign out previous session          │
│    - Trigger Google Sign-In flow        │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Google OAuth Web View               │
│    - User selects Google account        │
│    - Grant permissions                  │
│    - Return idToken                     │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Call AuthProvider.loginWithGoogle() │
│    - Send idToken to backend            │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend: AuthController.Google()    │
│    - Verify idToken with Google         │
│    - Extract email from Google profile  │
│    - Find or create user                │
│    - Generate JWT token                 │
│    - Return AuthResponse                │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 5. Save token & Navigate to Home       │
└─────────────────────────────────────────┘
```

#### C. Xác thực 2 yếu tố (2FA)

```
After Login with 2FA enabled
         ↓
┌─────────────────────────────────────────┐
│ 1. TwoFaLoginScreen                     │
│    - Enter 6-digit code from email      │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. POST /auth/verify-2fa                │
│    Body: { userId, code }               │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Backend Verify Code                  │
│    - Check code matches & not expired   │
│    - Generate JWT token                 │
│    - Return AuthResponse                │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Login success, navigate to Home     │
└─────────────────────────────────────────┘
```

### 3. LUỒNG LẤY DỮ LIỆU (DATA FETCHING FLOW)

```
Screen Mounted (e.g., HomeScreen)
         ↓
┌─────────────────────────────────────────┐
│ 1. Consumer<Provider> widget           │
│    - Listen to Provider changes         │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Provider.fetchData()                 │
│    - Set isLoading = true               │
│    - Call Service method                │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Service → API GET request           │
│    - Add JWT token to headers           │
│    - Send HTTP request                  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend Controller                   │
│    - Verify JWT token                   │
│    - Check authorization                │
│    - Query database via EF Core         │
│    - Return JSON data                   │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 5. Service parses JSON                  │
│    - Convert to Model objects           │
│    - Return to Provider                 │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 6. Provider updates state               │
│    - Store data in memory               │
│    - Set isLoading = false              │
│    - notifyListeners()                  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 7. UI Rebuilds                          │
│    - Display data in widgets            │
└─────────────────────────────────────────┘
```

### 4. LUỒNG THI (EXAM TAKING FLOW)

```
User selects exam from list
         ↓
┌─────────────────────────────────────────┐
│ 1. HomeScreen - Tap exam card           │
│    - Navigate to QuizScreen             │
│    - Pass DeThi object                  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. QuizScreen.initState()               │
│    - Call ThiProvider.startExam()       │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. ThiProvider.startExam()              │
│    - POST /thi/bat-dau                  │
│    - Body: { deThiId }                  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend: ThiController.BatDauThi()  │
│    - Get random questions from topic    │
│    - Record exam session (KetQuaThi)   │
│    - Start timer (ThoiGianBatDau)      │
│    - Return: sessionId, questions       │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 5. QuizScreen displays questions        │
│    - Show question by question          │
│    - Start countdown timer              │
│    - User selects answers               │
│    - Answers stored in local state      │
└─────────────────────────────────────────┘
         ↓
User taps "Nộp bài" or Timer expires
         ↓
┌─────────────────────────────────────────┐
│ 6. ThiProvider.submitExam()             │
│    - POST /thi/nop-bai                  │
│    - Body: { ketQuaThiId, answers[] }   │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 7. Backend: ThiController.NopBai()     │
│    - Validate submission time           │
│    - Calculate score (auto-grade)       │
│    - Save ChiTietKetQuaThi records     │
│    - Update KetQuaThi with score        │
│    - Return detailed results            │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 8. Navigate to ResultScreen             │
│    - Show score, correct/wrong answers  │
│    - Show detailed explanation          │
│    - Option to review                   │
└─────────────────────────────────────────┘
```

### 5. LUỒNG ADMIN QUẢN LÝ (ADMIN MANAGEMENT FLOW)

#### A. Quản lý câu hỏi (Question Management)

```
Admin Dashboard → Câu hỏi Tab
         ↓
┌─────────────────────────────────────────┐
│ 1. Load questions                       │
│    - GET /cau-hoi                       │
│    - Display in list with filters       │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Actions available:                   │
│    A. Create new question               │
│    B. Edit existing question            │
│    C. Delete question                   │
│    D. Import from Excel                 │
└─────────────────────────────────────────┘

Option A: Create New
         ↓
┌─────────────────────────────────────────┐
│ 1. Show dialog with form                │
│    - Content (Nội dung)                 │
│    - Answer A, B, C, D                  │
│    - Correct answer                     │
│    - Topic (Chủ đề)                     │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. POST /cau-hoi                        │
│    - Validate all fields                │
│    - Save to database                   │
│    - Return created question            │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Refresh question list                │
└─────────────────────────────────────────┘

Option D: Import from Excel
         ↓
┌─────────────────────────────────────────┐
│ 1. Select topic for import              │
│    - Dropdown: Chủ đề Excel             │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Tap "Import Excel" button            │
│    - FilePicker opens (.xlsx only)      │
│    - User selects file                  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. POST /cau-hoi/import-excel           │
│    - Multipart/form-data upload         │
│    - Body: file + topicId               │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend: CauHoiController.Import()  │
│    - Read Excel file (EPPlus library)   │
│    - Validate each row                  │
│    - Bulk insert to database            │
│    - Return success count               │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 5. Show success message                 │
│    "Đã import X câu hỏi thành công"    │
│    - Refresh question list              │
└─────────────────────────────────────────┘
```

#### B. Quản lý đề thi (Exam Management)

```
Admin Dashboard → Đề thi Tab
         ↓
┌─────────────────────────────────────────┐
│ 1. Create Exam Dialog                   │
│    - Tên đề thi                         │
│    - Chủ đề (select)                    │
│    - Số câu hỏi                         │
│    - Thời gian thi (phút)               │
│    - Trạng thái (Mở/Đóng)               │
│    - Cho phép thi nhiều lần?            │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Validate constraints                 │
│    - Check topic has enough questions   │
│    - soCauHoi <= available questions    │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. POST /de-thi                         │
│    - Save exam template                 │
│    - No actual questions stored yet     │
│    - Questions randomized on exam start │
└─────────────────────────────────────────┘
```

#### C. Quản lý người dùng (User Management)

```
Admin Dashboard → Người dùng Tab
         ↓
┌─────────────────────────────────────────┐
│ 1. GET /users?page=1&keyword=...        │
│    - Paginated list of users            │
│    - Search by name/email               │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Actions available:                   │
│    - Create new account                 │
│    - Edit roles (User/Admin)            │
│    - Lock/Unlock account                │
│    - Delete user                        │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Lock/Unlock flow:                    │
│    PATCH /users/{id}/lock               │
│    - Toggle LockoutEnd field            │
│    - If lock: set to 100 years future   │
│    - If unlock: set to null             │
└─────────────────────────────────────────┘
```

### 6. LUỒNG XEM KẾT QUẢ (VIEW RESULTS FLOW)

```
User → Profile → Tab "Kết quả"
         ↓
┌─────────────────────────────────────────┐
│ 1. KetQuaThiProvider.fetchMyResults()  │
│    - GET /ket-qua-thi                   │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Backend returns list of results      │
│    - Exam name, score, date, status     │
│    - Sorted by date desc                │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Display result cards                 │
│    - Green: Passed                      │
│    - Red: Failed                        │
│    - Tap to view details                │
└─────────────────────────────────────────┘
         ↓
User taps result card
         ↓
┌─────────────────────────────────────────┐
│ 4. GET /ket-qua-thi/{id}/chi-tiet      │
│    - Fetch detailed answers             │
│    - For each question:                 │
│      * Question content                 │
│      * User's answer                    │
│      * Correct answer                   │
│      * Is correct?                      │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 5. Navigate to ResultScreen             │
│    - Show question-by-question review   │
│    - Highlight correct/wrong            │
│    - Show explanation (if available)    │
└─────────────────────────────────────────┘
```

### 7. LUỒNG LIÊN HỆ/FEEDBACK (CONTACT FLOW)

```
User → ContactScreen
         ↓
┌─────────────────────────────────────────┐
│ 1. Fill contact form                    │
│    - Subject (optional)                 │
│    - Message content                    │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. POST /lien-he                        │
│    - Body: { noiDung }                  │
│    - User ID from JWT                   │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Backend: LienHeController.Create()  │
│    - Save to database                   │
│    - TrangThai = "ChuaDoc"              │
│    - NgayGui = now                      │
│    - Optional: Send email to admin      │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Admin Dashboard → Liên hệ Tab        │
│    - View all messages                  │
│    - Mark as read                       │
│    - Delete messages                    │
└─────────────────────────────────────────┘
```

---

## 🔐 BẢO MẬT VÀ AUTHENTICATION

### JWT Token Flow

```
┌─────────────────────────────────────────┐
│ Token Structure:                        │
│                                         │
│ Header:                                 │
│   - alg: "HS256"                        │
│   - typ: "JWT"                          │
│                                         │
│ Payload (Claims):                       │
│   - sub: userId                         │
│   - email: user email                   │
│   - name: user full name                │
│   - role: ["User"] or ["Admin"]         │
│   - exp: expiration timestamp           │
│                                         │
│ Signature:                              │
│   - HMACSHA256(header + payload, key)   │
└─────────────────────────────────────────┘

Token Lifecycle:
┌─────────────────────────────────────────┐
│ 1. Login Success                        │
│    → Backend generates JWT              │
│    → Returns { token, expiresAt, user } │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 2. Client Stores Token                  │
│    → TokenStorage (flutter_secure_storage) │
│    → Encrypted local storage            │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 3. Every API Request                    │
│    → Add header:                        │
│      Authorization: Bearer {token}      │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ 4. Backend Validates Token              │
│    → Verify signature                   │
│    → Check expiration                   │
│    → Extract user claims                │
│    → Check authorization [Authorize]    │
└─────────────────────────────────────────┘
         ↓
    ┌────┴────┐
    │         │
 Valid?    Invalid/Expired
    │         │
    ↓         ↓
 Process   Return 401
 Request   Unauthorized
    │         │
    │         ↓
    │    ┌─────────────┐
    │    │ Client:     │
    │    │ - Clear     │
    │    │   token     │
    │    │ - Navigate  │
    │    │   to Login  │
    │    └─────────────┘
    ↓
 Success
```

### Authorization Levels

```
┌──────────────────────────────────────────────┐
│ PUBLIC ENDPOINTS (No auth required):         │
│  - POST /auth/login                          │
│  - POST /auth/register                       │
│  - POST /auth/google                         │
│  - POST /auth/forgot-password                │
│  - POST /auth/reset-password                 │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ USER ENDPOINTS [Authorize]:                  │
│  - GET  /de-thi (open exams)                 │
│  - POST /thi/bat-dau                         │
│  - POST /thi/nop-bai                         │
│  - GET  /ket-qua-thi (own results)           │
│  - POST /binh-luan                           │
│  - POST /lien-he                             │
│  - GET  /auth/profile                        │
│  - PUT  /auth/profile                        │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ ADMIN ENDPOINTS [Authorize(Roles="Admin")]:  │
│  - ALL /users/* endpoints                    │
│  - POST /chu-de                              │
│  - PUT  /chu-de/{id}                         │
│  - DELETE /chu-de/{id}                       │
│  - POST /cau-hoi                             │
│  - POST /cau-hoi/import-excel                │
│  - PUT  /cau-hoi/{id}                        │
│  - DELETE /cau-hoi/{id}                      │
│  - POST /de-thi                              │
│  - PUT  /de-thi/{id}                         │
│  - DELETE /de-thi/{id}                       │
│  - GET  /de-thi (all, including closed)      │
│  - GET  /lien-he/admin                       │
│  - DELETE /lien-he/{id}                      │
└──────────────────────────────────────────────┘
```

---

## 💾 DATABASE SCHEMA

### Entity Relationships

```
┌─────────────────┐
│ ApplicationUser │ (Identity Framework)
│─────────────────│
│ Id (PK)         │───┐
│ UserName        │   │
│ Email           │   │ 1
│ FullName        │   │
│ TwoFactorEnabled│   │
│ LockoutEnd      │   │
│ Roles[]         │   │
└─────────────────┘   │
                      │
    ┌─────────────────┼─────────────────┬─────────────────┐
    │                 │                 │                 │
    │ N               │ N               │ N               │ N
    ↓                 ↓                 ↓                 ↓
┌─────────┐    ┌──────────────┐  ┌───────────┐   ┌──────────┐
│ LienHe  │    │ KetQuaThi    │  │ BinhLuan  │   │ (Creator)│
│─────────│    │──────────────│  │───────────│   │  ChuDe   │
│ Id (PK) │    │ Id (PK)      │  │ Id (PK)   │   │  CauHoi  │
│ TaiKhoan│←───│ TaiKhoanId   │  │ TaiKhoan  │   │  DeThi   │
│  Id (FK)│    │   (FK)       │  │  Id (FK)  │   └──────────┘
│ NoiDung │    │ DeThiId (FK) │  │ NoiDung   │
│ NgayGui │    │ Diem         │  │ NgayTao   │
│ TrangThai│   │ ThoiGianBD   │  │ Rating    │
└─────────┘    │ ThoiGianKT   │  └───────────┘
               │ TrangThai    │
               └──────────────┘
                      │
                      │ 1
                      ↓
               ┌──────────────┐
               │ DeThi        │
               │──────────────│
               │ Id (PK)      │───┐
               │ TenDeThi     │   │
               │ ChuDeId (FK) │   │ 1
               │ SoCauHoi     │   │
               │ ThoiGianThi  │   │
               │ TrangThai    │   │
               │ AllowMultiple│   │
               │  Attempts    │   │
               └──────────────┘   │
                                  │
    ┌─────────────────────────────┤
    │                             │
    │ N                           │ N
    ↓                             ↓
┌─────────────────┐      ┌──────────────────┐
│ ChiTietKetQuaThi│      │ CauHoi           │
│─────────────────│      │──────────────────│
│ Id (PK)         │      │ Id (PK)          │
│ KetQuaThiId(FK) │      │ NoiDung          │
│ CauHoiId (FK)   │──────│ DapAnA           │
│ DapAnDaChon     │  N→1 │ DapAnB           │
│ DungSai         │      │ DapAnC (null)    │
└─────────────────┘      │ DapAnD (null)    │
                         │ DapAnDung        │
                         │ ChuDeId (FK)     │
                         │ HinhAnh (null)   │
                         │ AmThanh (null)   │
                         └──────────────────┘
                                  ↑
                                  │ N
                                  │
                                  │ 1
                         ┌──────────────────┐
                         │ ChuDe            │
                         │──────────────────│
                         │ Id (PK)          │
                         │ TenChuDe         │
                         │ MoTa (null)      │
                         │ NgayTao          │
                         └──────────────────┘
```

### Key Constraints

```sql
-- Primary Keys
PK_Users ON ApplicationUser(Id)
PK_ChuDe ON ChuDe(Id)
PK_CauHoi ON CauHoi(Id)
PK_DeThi ON DeThi(Id)
PK_KetQuaThi ON KetQuaThi(Id)
PK_ChiTietKetQuaThi ON ChiTietKetQuaThi(Id)
PK_BinhLuan ON BinhLuan(Id)
PK_LienHe ON LienHe(Id)

-- Foreign Keys with Cascade
FK_CauHoi_ChuDe: CauHoi.ChuDeId → ChuDe.Id
  ON DELETE: Restrict (cannot delete topic with questions)

FK_DeThi_ChuDe: DeThi.ChuDeId → ChuDe.Id
  ON DELETE: Restrict

FK_KetQuaThi_User: KetQuaThi.TaiKhoanId → User.Id
  ON DELETE: Restrict

FK_KetQuaThi_DeThi: KetQuaThi.DeThiId → DeThi.Id
  ON DELETE: Restrict

FK_ChiTietKetQuaThi_KetQuaThi: ChiTietKetQuaThi.KetQuaThiId → KetQuaThi.Id
  ON DELETE: Cascade (delete details when parent deleted)

FK_ChiTietKetQuaThi_CauHoi: ChiTietKetQuaThi.CauHoiId → CauHoi.Id
  ON DELETE: Restrict

FK_BinhLuan_User: BinhLuan.TaiKhoanId → User.Id
  ON DELETE: Restrict

FK_LienHe_User: LienHe.TaiKhoanId → User.Id
  ON DELETE: Restrict

-- Indexes
IX_CauHoi_ChuDeId ON CauHoi(ChuDeId)
IX_DeThi_ChuDeId ON DeThi(ChuDeId)
IX_KetQuaThi_TaiKhoanId ON KetQuaThi(TaiKhoanId)
IX_KetQuaThi_DeThiId ON KetQuaThi(DeThiId)
```

---

## 🎨 UI/UX DESIGN PATTERNS

### Material Design 3 Theme

```dart
Primary Color: #2196F3 (Blue)
Secondary Color: #4CAF50 (Green)
Error Color: #F44336 (Red)
Background: #FAFAFA (Light Grey)
Surface: #FFFFFF (White)

Design Size: 390x844 (iPhone 14 Pro)
Responsive: ScreenUtil with .w, .h, .sp, .r extensions
```

### Screen Layouts

```
┌─────────────────────────────────────────┐
│ Common Layout Pattern:                  │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ AppBar                              │ │
│ │ - Title                             │ │
│ │ - Back button (if nested)           │ │
│ │ - Action buttons                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Body (SafeArea)                     │ │
│ │                                     │ │
│ │ Responsive padding: 16.w, 20.w      │ │
│ │                                     │ │
│ │ Scrollable content:                 │ │
│ │ - ListView                          │ │
│ │ - GridView                          │ │
│ │ - SingleChildScrollView             │ │
│ │                                     │ │
│ │ Pull-to-refresh: RefreshIndicator   │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Bottom Navigation (if applicable)   │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Card Design Pattern

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8-10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  padding: EdgeInsets.all(16.w),
  child: [...content...]
)
```

### Button Styles

```dart
// Primary Action Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primary color,
    foregroundColor: white,
    elevation: 2-4,
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    ),
  ),
  child: Text,
)

// Secondary Action Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: primary, width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
  ),
  child: Text,
)

// Action Button with Gradient
Container with gradient + Material + InkWell
```

---

## 🚀 DEPLOYMENT & CONFIGURATION

### Backend Configuration

```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=...;User Id=...;Password=...;"
  },
  "Jwt": {
    "Key": "your-secret-key-min-32-chars",
    "Issuer": "ThiTracNghiemApi",
    "Audience": "ThiTracNghiemApp",
    "ExpireMinutes": 60
  },
  "Smtp": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "Username": "your-email@gmail.com",
    "Password": "app-password",
    "FromEmail": "your-email@gmail.com",
    "FromName": "Smart Test System"
  },
  "GoogleAuth": {
    "ClientId": "your-google-client-id.apps.googleusercontent.com"
  }
}
```

### Frontend Configuration

```bash
# .env file
BASE_URL=http://10.0.2.2:5000
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
```

### Build Commands

```bash
# Backend
cd ThiTracNghiemApi
dotnet restore
dotnet ef database update
dotnet run

# Frontend
cd thitracnghiemapp
flutter pub get
flutter run

# Production builds
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## 📊 API ENDPOINTS SUMMARY

### Authentication
```
POST   /auth/register              - Register new user
POST   /auth/login                 - Login with username/password
POST   /auth/google                - Login with Google
POST   /auth/verify-2fa            - Verify 2FA code
POST   /auth/resend-2fa            - Resend 2FA code
POST   /auth/forgot-password       - Request password reset
POST   /auth/reset-password        - Reset password with token
GET    /auth/profile               - Get current user profile
PUT    /auth/profile               - Update profile
POST   /auth/change-password       - Change password
POST   /auth/enable-2fa            - Enable 2FA
POST   /auth/disable-2fa           - Disable 2FA
```

### Topics (Chủ đề)
```
GET    /chu-de                     - Get all topics
GET    /chu-de/{id}                - Get topic by ID
POST   /chu-de                     - Create topic [Admin]
PUT    /chu-de/{id}                - Update topic [Admin]
DELETE /chu-de/{id}                - Delete topic [Admin]
```

### Questions (Câu hỏi)
```
GET    /cau-hoi                    - Get questions (with filters)
GET    /cau-hoi/{id}               - Get question by ID
POST   /cau-hoi                    - Create question [Admin]
POST   /cau-hoi/import-excel       - Import from Excel [Admin]
PUT    /cau-hoi/{id}               - Update question [Admin]
DELETE /cau-hoi/{id}               - Delete question [Admin]
```

### Exams (Đề thi)
```
GET    /de-thi                     - Get open exams (or all for admin)
GET    /de-thi/{id}                - Get exam by ID
POST   /de-thi                     - Create exam [Admin]
PUT    /de-thi/{id}                - Update exam [Admin]
DELETE /de-thi/{id}                - Delete exam [Admin]
```

### Taking Exam (Thi)
```
POST   /thi/bat-dau                - Start exam session
POST   /thi/nop-bai                - Submit exam
```

### Results (Kết quả thi)
```
GET    /ket-qua-thi                - Get my results
GET    /ket-qua-thi/{id}           - Get result by ID
GET    /ket-qua-thi/{id}/chi-tiet  - Get detailed answers
GET    /ket-qua-thi/thong-ke       - Get statistics
```

### Comments (Bình luận)
```
GET    /binh-luan                  - Get comments (with filters)
POST   /binh-luan                  - Create comment
PUT    /binh-luan/{id}             - Update comment
DELETE /binh-luan/{id}             - Delete comment
```

### Contact (Liên hệ)
```
POST   /lien-he                    - Send contact message
GET    /lien-he/admin              - Get all messages [Admin]
DELETE /lien-he/{id}               - Delete message [Admin]
```

### User Management (Admin only)
```
GET    /users                      - Get users (paginated, search)
GET    /users/{id}                 - Get user by ID
POST   /users                      - Create user
PATCH  /users/{id}/roles           - Update roles
PATCH  /users/{id}/lock            - Lock/unlock user
DELETE /users/{id}                 - Delete user
```

---

## 🔧 TROUBLESHOOTING

### Common Issues

1. **"Cannot connect to API"**
   - Check BASE_URL in .env
   - Android emulator: use 10.0.2.2 instead of localhost
   - iOS simulator: use localhost or real IP
   - Check backend is running

2. **"Unauthorized" after login**
   - Token expired, re-login
   - Clear app data
   - Check JWT configuration matches

3. **Images not loading**
   - Run `flutter pub get` after adding to assets
   - Check pubspec.yaml assets section
   - Hot restart (not hot reload)

4. **Database errors**
   - Run `dotnet ef database update`
   - Check connection string
   - Ensure SQL Server is running

5. **Google login not working**
   - Check GOOGLE_CLIENT_ID in both frontend and backend
   - Verify OAuth consent screen configured
   - Check SHA-1 fingerprint for Android

---

## 📝 DEVELOPMENT BEST PRACTICES

### Code Organization
- Follow SOLID principles
- Use async/await for all API calls
- Handle errors gracefully with try-catch
- Show loading states during async operations
- Provide user feedback (SnackBar, Dialog)

### State Management
- Use Provider for global state
- Keep UI widgets stateless when possible
- Call notifyListeners() after state changes
- Dispose controllers and listeners

### API Design
- RESTful conventions
- Consistent error responses
- Paginate large datasets
- Use DTOs for data transfer
- Validate inputs server-side

### Security
- Never store sensitive data in plain text
- Use HTTPS in production
- Validate JWT on every protected endpoint
- Sanitize user inputs
- Implement rate limiting

### Testing
- Unit tests for business logic
- Integration tests for API endpoints
- Widget tests for UI components
- Test error handling paths

---

## 📚 DEPENDENCIES

### Backend
```xml
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.0.0" />
<PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="9.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="9.0.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="9.0.0" />
<PackageReference Include="EPPlus" Version="7.5.2" /> <!-- Excel import -->
<PackageReference Include="Google.Apis.Auth" Version="1.68.0" /> <!-- Google OAuth -->
```

### Frontend
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5+1          # State management
  http: ^1.5.0                # HTTP client
  flutter_secure_storage: ^9.2.4  # Secure storage
  flutter_screenutil: ^5.9.3  # Responsive UI
  google_sign_in: ^6.2.1      # Google OAuth
  google_fonts: ^6.2.1        # Fonts
  cached_network_image: ^3.4.1  # Image caching
  file_picker: ^10.3.3        # File picker
  intl: ^0.20.2               # Internationalization
  fl_chart: ^0.69.0           # Charts
  qr_flutter: ^4.1.0          # QR codes
  flutter_dotenv: ^6.0.0      # Environment variables
```

---

## 🎯 FUTURE ENHANCEMENTS

1. **Real-time features**
   - Live leaderboard during exams
   - Chat support with admin
   - Push notifications

2. **Advanced exam features**
   - Question shuffling
   - Answer shuffling
   - Essay questions (manual grading)
   - Image/audio questions
   - Detailed analytics

3. **Gamification**
   - Badges and achievements
   - Point system
   - User rankings
   - Study streaks

4. **Admin features**
   - Bulk operations
   - Advanced analytics dashboard
   - Export reports (PDF, Excel)
   - Email notifications

5. **Performance**
   - Caching strategies
   - Lazy loading
   - Database indexing optimization
   - CDN for static assets

---

**Document Version**: 1.0  
**Last Updated**: October 31, 2025  
**Author**: Development Team  
**Project**: Smart Test - Hệ thống thi trắc nghiệm thông minh
