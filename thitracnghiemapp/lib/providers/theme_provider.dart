import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load theme preference from storage
  Future<void> _loadTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _isDarkMode = false;
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveTheme();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      await _saveTheme();
    }
  }

  /// Save theme preference to storage
  Future<void> _saveTheme() async {
    try {
      await _prefs?.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Màu chủ đạo - GIỐNG CHÍNH XÁC THEME CŨ
  static const Color primaryLight = Color(0xFF2196F3); // Blue
  static const Color primaryLightBackground = Color(0xFFE3F2FD); // Light Blue
  static const Color secondaryLight = Color(0xFF03A9F4); // Light Blue accent
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color backgroundLight = Color(0xFFFAFAFA); // Very light grey
  static const Color errorLight = Color(0xFFD32F2F); // Red

  // Dark mode colors
  static const Color primaryDark = Color(0xFF90CAF9);
  static const Color primaryDarkBackground = Color(0xFF1E1E1E);
  static const Color secondaryDark = Color(0xFF81D4FA);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color errorDark = Color(0xFFEF5350);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Get light theme data - CHÍNH XÁC THEME CŨ
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.light,
      primary: primaryLight,
      secondary: secondaryLight,
      surface: surfaceLight,
      error: errorLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      brightness: Brightness.light,

      // Typography - Poppins font - GIỐNG CHÍNH XÁC
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: textPrimaryLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.normal,
          color: textPrimaryLight,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
          color: textSecondaryLight,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: textSecondaryLight,
        ),
      ),

      // AppBar Theme - CHÍNH XÁC THEME CŨ
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        toolbarHeight: 56.h,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 22.sp),
      ),

      // Card Theme - BORDER RADIUS 8.r GIỐNG CŨ
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceLight,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      ),

      // Button Themes - CHÍNH XÁC THEME CŨ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme - BORDER RADIUS 8.r GIỐNG CŨ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorLight, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textSecondaryLight,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textSecondaryLight,
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12.sp, color: errorLight),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: primaryLight, size: 24.sp),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryLightBackground,
        labelStyle: GoogleFonts.poppins(fontSize: 12.sp, color: primaryLight),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textPrimaryLight,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),

      // BottomNavigationBar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondaryLight,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // NavigationBar Theme (mới)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryLight.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLight,
      ),
    );
  }

  /// Get dark theme data - PHIÊN BẢN TỐI CỦA THEME CŨ
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      primary: primaryDark,
      secondary: secondaryDark,
      surface: surfaceDark,
      error: errorDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      brightness: Brightness.dark,

      // Typography - Poppins font - GIỐNG CHÍNH XÁC NHƯNG MÀU TỐI
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.normal,
          color: textPrimaryDark,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
          color: textSecondaryDark,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: textSecondaryDark,
        ),
      ),

      // AppBar Theme - BACKGROUND TỐI THAY VÌ XANH
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: surfaceDark, // Thay đổi: tối thay vì xanh
        foregroundColor: textPrimaryDark,
        toolbarHeight: 56.h,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark, size: 22.sp),
      ),

      // Card Theme - BACKGROUND TỐI
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceDark, // Thay đổi: #2C2C2C thay vì trắng
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r), // GIỮ NGUYÊN 8.r
        ),
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      ),

      // Button Themes - MÀU TỐI
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryDark,
          foregroundColor: backgroundDark,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r), // GIỮ NGUYÊN 8.r
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          side: const BorderSide(color: primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r), // GIỮ NGUYÊN 8.r
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme - BACKGROUND VÀ BORDER TỐI
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark, // Thay đổi: background tối
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r), // GIỮ NGUYÊN 8.r
          borderSide: BorderSide(color: Colors.grey.shade700), // Border tối
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorDark, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorDark, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textSecondaryDark,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textSecondaryDark,
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12.sp, color: errorDark),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: primaryDark, size: 24.sp),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: backgroundDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryDarkBackground,
        labelStyle: GoogleFonts.poppins(fontSize: 12.sp, color: primaryDark),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textPrimaryDark,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),

      // BottomNavigationBar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark, // Background tối
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondaryDark,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // NavigationBar Theme - BACKGROUND TỐI
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark, // Background tối
        indicatorColor: primaryDark.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800, // Divider tối
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryDark,
      ),
    );
  }
}
