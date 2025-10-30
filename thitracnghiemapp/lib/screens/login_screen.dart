import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../core/app_env.dart';
import '../providers/auth_provider.dart';
import '../utils/ui_helpers.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid') ||
        lower.contains('unauthorized') ||
        lower.contains('không hợp lệ')) {
      return 'Sai tên đăng nhập hoặc mật khẩu. Vui lòng thử lại.';
    }
    if (lower.contains('locked')) {
      return 'Tài khoản tạm thời bị khóa. Vui lòng thử lại sau.';
    }
    if (lower.contains('not found') || lower.contains('không tìm thấy')) {
      return 'Tài khoản không tồn tại.';
    }
    if (lower.contains('network') || lower.contains('timeout')) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra internet và thử lại.';
    }
    return raw;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 16.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: UIHelpers.maxFormWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo & Name Section
                    _buildAppHeader(theme),

                    UIHelpers.verticalSpaceLarge(),

                    // Login Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: UIHelpers.paddingAll(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Đăng nhập',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Username/Email Field
                              TextFormField(
                                controller: _identifierController,
                                decoration: InputDecoration(
                                  labelText: 'Tên đăng nhập hoặc email',
                                  hintText: 'Nhập tên đăng nhập hoặc email',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: 20.sp,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Vui lòng nhập tên đăng nhập hoặc email'
                                    : null,
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  hintText: 'Nhập mật khẩu',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    size: 20.sp,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20.sp,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(auth),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu tối thiểu 6 ký tự';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        ),
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ),
                              ),

                              UIHelpers.verticalSpaceSmall(),

                              // Login Button
                              SizedBox(
                                height: UIHelpers.buttonHeight,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => _login(auth),
                                  child: auth.isLoading
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Đăng nhập',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Divider with "hoặc"
                              Row(
                                children: [
                                  Expanded(child: Divider(thickness: 1.w)),
                                  Padding(
                                    padding: UIHelpers.paddingHorizontal(12),
                                    child: Text(
                                      'hoặc',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(thickness: 1.w)),
                                ],
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Google Login Button
                              SizedBox(
                                height: UIHelpers.buttonHeight,
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.login, size: 20.sp),
                                  label: Text(
                                    'Đăng nhập với Google',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => _loginWithGoogle(auth),
                                ),
                              ),

                              // Error Message
                              if (auth.error != null) ...[
                                UIHelpers.verticalSpaceMedium(),
                                Container(
                                  padding: UIHelpers.paddingAll(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: theme.colorScheme.error,
                                        size: 20.sp,
                                      ),
                                      UIHelpers.horizontalSpaceSmall(),
                                      Expanded(
                                        child: Text(
                                          _friendlyAuthError(auth.error!),
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    UIHelpers.verticalSpaceMedium(),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                          ),
                          child: Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(ThemeData theme) {
    return Column(
      children: [
        // App Icon/Logo
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(8.w),
          child: ClipOval(
            child: Image.asset('assets/quizlogo.png', fit: BoxFit.cover),
          ),
        ),

        UIHelpers.verticalSpaceMedium(),

        // App Name
        Text(
          'Smart Test',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),

        UIHelpers.verticalSpaceSmall(),

        // Subtitle
        Text(
          'Hệ thống thi trắc nghiệm thông minh',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _loginWithGoogle(AuthProvider auth) async {
    try {
      final serverClientId = AppEnv.googleClientId;
      if (serverClientId == null || serverClientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa cấu hình GOOGLE_CLIENT_ID trong file .env'),
          ),
        );
        return;
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ['email'],
        clientId: Platform.isIOS ? serverClientId : null,
        serverClientId: serverClientId,
      );
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // Ignore if there is no previous session to disconnect
      }
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không nhận được mã xác thực từ Google'),
          ),
        );
        return;
      }

      final success = await auth.loginWithGoogle(idToken: idToken);
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (!success && mounted && auth.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.error!)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập Google thất bại: $error')),
      );
    }
  }

  Future<void> _login(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }
    // If not success, check if 2FA is required
    if (auth.pendingTwoFaUserId != null) {
      Navigator.of(context).pushReplacementNamed('/login-2fa');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _friendlyAuthError(
            auth.error ??
                'Đăng nhập không thành công. Vui lòng kiểm tra thông tin.',
          ),
        ),
      ),
    );
  }
}
