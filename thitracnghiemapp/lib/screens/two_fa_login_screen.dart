import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/ui_helpers.dart';

class TwoFaLoginScreen extends StatefulWidget {
  const TwoFaLoginScreen({super.key});

  @override
  State<TwoFaLoginScreen> createState() => _TwoFaLoginScreenState();
}

class _TwoFaLoginScreenState extends State<TwoFaLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Xác thực 2 bước'), centerTitle: true),
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
                children: [
                  // 2FA Icon Header
                  _build2FAHeader(theme),

                  UIHelpers.verticalSpaceLarge(),

                  // 2FA Form Card
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
                              'Nhập mã xác thực',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            UIHelpers.verticalSpaceSmall(),

                            // Description
                            Text(
                              'Mở ứng dụng Google Authenticator và nhập mã 6 số hiển thị',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            UIHelpers.verticalSpaceLarge(),

                            // Code Input Field
                            TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Mã xác thực',
                                hintText: '000000',
                                prefixIcon: Icon(
                                  Icons.security_outlined,
                                  size: 20.sp,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8.w,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _verify(auth),
                              validator: (v) =>
                                  v == null || v.trim().length != 6
                                  ? 'Vui lòng nhập 6 số'
                                  : null,
                            ),

                            UIHelpers.verticalSpaceLarge(),

                            // Verify Button
                            SizedBox(
                              height: UIHelpers.buttonHeight,
                              child: ElevatedButton.icon(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _verify(auth),
                                icon: auth.isLoading
                                    ? SizedBox(
                                        width: 18.w,
                                        height: 18.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.check_circle, size: 20.sp),
                                label: Text(
                                  auth.isLoading
                                      ? 'Đang xác thực...'
                                      : 'Xác nhận',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            UIHelpers.verticalSpaceMedium(),

                            // Helper Text
                            Container(
                              padding: UIHelpers.paddingAll(12),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                                      'Mã xác thực thay đổi sau mỗi 30 giây',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build2FAHeader(ThemeData theme) {
    return Column(
      children: [
        // 2FA Icon
        Container(
          width: 80.w,
          height: 80.h,
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
            Icons.verified_user_outlined,
            size: 40.sp,
            color: Colors.white,
          ),
        ),

        UIHelpers.verticalSpaceMedium(),

        // Title
        Text(
          'Bảo mật nâng cao',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),

        UIHelpers.verticalSpaceSmall(),

        // Subtitle
        Text(
          'Tài khoản của bạn được bảo vệ bằng xác thực 2 bước',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _verify(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await auth.completeLoginWith2Fa(
      code: _codeController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      UIHelpers.showSuccessSnackBar(context, 'Xác thực thành công!');
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (auth.error != null) {
      UIHelpers.showErrorSnackBar(
        context,
        auth.error ?? 'Mã xác thực không đúng. Vui lòng thử lại.',
      );
    }
  }
}
