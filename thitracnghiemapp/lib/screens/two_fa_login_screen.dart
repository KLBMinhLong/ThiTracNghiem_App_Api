import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực 2 bước')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nhập mã 6 số từ ứng dụng Google Authenticator',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã xác thực',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => v == null || v.trim().length != 6
                        ? 'Vui lòng nhập 6 số'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final ok = await auth.completeLoginWith2Fa(
                                code: _codeController.text.trim(),
                              );
                              if (!mounted) return;
                              if (ok) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/home');
                              } else if (auth.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(auth.error!)),
                                );
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xác nhận'),
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
}
