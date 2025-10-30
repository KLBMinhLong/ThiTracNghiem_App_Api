import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/ui_helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('email') &&
        (lower.contains('exists') ||
            lower.contains('đã tồn tại') ||
            lower.contains('already'))) {
      return 'Email đã được sử dụng. Vui lòng chọn email khác.';
    }
    if (lower.contains('username') &&
        (lower.contains('exists') ||
            lower.contains('đã tồn tại') ||
            lower.contains('already'))) {
      return 'Tên đăng nhập đã được sử dụng. Vui lòng chọn tên khác.';
    }
    if (lower.contains('weak') ||
        lower.contains('mật khẩu') && lower.contains('yếu')) {
      return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
    }
    if (lower.contains('network') || lower.contains('timeout')) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra internet và thử lại.';
    }
    return raw;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Đăng ký tài khoản'), centerTitle: true),
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
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(theme),

                    UIHelpers.verticalSpaceLarge(),

                    // Register Form Card
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
                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Tên đăng nhập',
                                  hintText: 'Nhập tên đăng nhập',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: 20.sp,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên đăng nhập';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Tên đăng nhập tối thiểu 3 ký tự';
                                  }
                                  return null;
                                },
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Full Name Field
                              TextFormField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  labelText: 'Họ và tên',
                                  hintText: 'Nhập họ và tên đầy đủ',
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    size: 20.sp,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập họ tên';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Họ tên tối thiểu 2 ký tự';
                                  }
                                  return null;
                                },
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'example@email.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20.sp,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  final email = value.trim();
                                  const pattern =
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                  if (!RegExp(pattern).hasMatch(email)) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  hintText: 'Tối thiểu 6 ký tự',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    size: 20.sp,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20.sp,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Mật khẩu tối thiểu 6 ký tự';
                                  }
                                  final hasLetter = RegExp(
                                    r'[A-Za-z]',
                                  ).hasMatch(value);
                                  final hasDigit = RegExp(
                                    r'\d',
                                  ).hasMatch(value);
                                  if (!(hasLetter && hasDigit)) {
                                    return 'Mật khẩu nên gồm cả chữ và số';
                                  }
                                  return null;
                                },
                              ),

                              UIHelpers.verticalSpaceMedium(),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Xác nhận mật khẩu',
                                  hintText: 'Nhập lại mật khẩu',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    size: 20.sp,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20.sp,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(auth),
                                validator: (value) =>
                                    value != _passwordController.text
                                    ? 'Mật khẩu xác nhận không khớp'
                                    : null,
                              ),

                              UIHelpers.verticalSpaceLarge(),

                              // Register Button
                              SizedBox(
                                height: UIHelpers.buttonHeight,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => _register(auth),
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
                                          'Đăng ký',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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

                    // Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                          ),
                          child: Text(
                            'Đăng nhập',
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

  Widget _buildWelcomeHeader(ThemeData theme) {
    return Column(
      children: [
        // Icon
        Container(
          width: 70.w,
          height: 70.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: 35.sp,
            color: Colors.white,
          ),
        ),

        UIHelpers.verticalSpaceMedium(),

        // Title
        Text(
          'Tạo tài khoản mới',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),

        UIHelpers.verticalSpaceSmall(),

        // Subtitle
        Text(
          'Điền thông tin bên dưới để đăng ký',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _register(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final success = await auth.register(
      userName: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      UIHelpers.showSuccessSnackBar(
        context,
        'Đăng ký thành công! Hãy đăng nhập để tiếp tục.',
      );
      Navigator.of(context).pop();
    } else {
      final msg = _friendlyAuthError(
        auth.error ?? 'Đăng ký không thành công. Vui lòng kiểm tra thông tin.',
      );
      UIHelpers.showErrorSnackBar(context, msg);
    }
  }
}
