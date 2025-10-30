import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/ui_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _emailSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Quên mật khẩu'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEmailCard(auth, theme),
                  UIHelpers.verticalSpaceLarge(),
                  _buildResetCard(auth, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCard(AuthProvider auth, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: UIHelpers.paddingAll(16),
        child: Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.mail_outline,
                      size: 20.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  UIHelpers.horizontalSpaceMedium(),
                  Expanded(
                    child: Text(
                      'Bước 1: Yêu cầu đặt lại',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              UIHelpers.verticalSpaceSmall(),
              Text(
                'Nhập email đã đăng ký để nhận mã đặt lại mật khẩu',
                style: theme.textTheme.bodySmall,
              ),
              UIHelpers.verticalSpaceMedium(),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20.sp),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  final email = value.trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              UIHelpers.verticalSpaceMedium(),
              SizedBox(
                width: double.infinity,
                height: UIHelpers.buttonHeight,
                child: ElevatedButton.icon(
                  icon: auth.isSendingResetEmail
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.send_outlined, size: 18.sp),
                  label: Text(
                    auth.isSendingResetEmail ? 'Đang gửi...' : 'Gửi mã',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  onPressed: auth.isSendingResetEmail
                      ? null
                      : () => _submitEmail(auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetCard(AuthProvider auth, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: UIHelpers.paddingAll(16),
        child: Form(
          key: _resetFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 20.sp,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  UIHelpers.horizontalSpaceMedium(),
                  Expanded(
                    child: Text(
                      'Bước 2: Đặt mật khẩu mới',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              UIHelpers.verticalSpaceSmall(),
              Text(
                'Nhập mã nhận được qua email và mật khẩu mới',
                style: theme.textTheme.bodySmall,
              ),
              UIHelpers.verticalSpaceMedium(),
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Mã đặt lại (token)',
                  hintText: 'Nhập mã từ email',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 20.sp),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã đặt lại';
                  }
                  return null;
                },
              ),
              UIHelpers.verticalSpaceMedium(),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  hintText: 'Tối thiểu 6 ký tự',
                  prefixIcon: Icon(Icons.lock_reset_outlined, size: 20.sp),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    }),
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20.sp,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              UIHelpers.verticalSpaceMedium(),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline, size: 20.sp),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20.sp,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              UIHelpers.verticalSpaceLarge(),
              SizedBox(
                width: double.infinity,
                height: UIHelpers.buttonHeight,
                child: ElevatedButton.icon(
                  icon: auth.isResettingPassword
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.check_circle_outline, size: 18.sp),
                  label: Text(
                    auth.isResettingPassword
                        ? 'Đang đặt lại...'
                        : 'Đặt lại mật khẩu',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  onPressed: auth.isResettingPassword
                      ? null
                      : () => _submitReset(auth),
                ),
              ),
              if (!_emailSent) ...[
                UIHelpers.verticalSpaceMedium(),
                Container(
                  padding: UIHelpers.paddingAll(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18.sp,
                        color: theme.colorScheme.primary,
                      ),
                      UIHelpers.horizontalSpaceSmall(),
                      Expanded(
                        child: Text(
                          'Gợi ý: Yêu cầu mã ở bước 1 trước',
                          style: theme.textTheme.bodySmall,
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
    );
  }

  Future<void> _submitEmail(AuthProvider auth) async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }
    final email = _emailController.text.trim();
    final error = await auth.sendPasswordResetEmail(email);
    if (!mounted) return;

    if (error == null) {
      setState(() => _emailSent = true);
      UIHelpers.showSuccessSnackBar(
        context,
        'Đã gửi mã đặt lại mật khẩu tới $email',
      );
    } else {
      UIHelpers.showErrorSnackBar(context, error);
    }
  }

  Future<void> _submitReset(AuthProvider auth) async {
    if (!_resetFormKey.currentState!.validate()) {
      return;
    }
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;
    final email = _emailController.text.trim();

    final error = await auth.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
    if (!mounted) return;

    if (error == null) {
      UIHelpers.showSuccessSnackBar(
        context,
        'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      UIHelpers.showErrorSnackBar(context, error);
    }
  }
}
