import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/de_thi.dart';
import '../models/quiz_session.dart';
import '../providers/auth_provider.dart';
import '../providers/ket_qua_thi_provider.dart';
import '../providers/thi_provider.dart';
import '../utils/ui_helpers.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final DeThi deThi;

  const QuizScreen({super.key, required this.deThi});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialiseSession();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    context.read<ThiProvider>().reset();
    super.dispose();
  }

  Future<void> _initialiseSession() async {
    final provider = context.read<ThiProvider>();
    if (provider.currentSession == null) {
      await provider.startThi(widget.deThi.id);
    }
    if (!mounted) {
      return;
    }
    final session = provider.currentSession;
    if (session != null) {
      _currentIndex = 0;
      _startTimer(session.thoiGianThi * 60);
    } else if (provider.error != null) {
      final friendlyMessage = provider.error!.length > 200
          ? 'Không thể tải bài thi. Vui lòng thử lại sau.'
          : provider.error!;
      UIHelpers.showErrorSnackBar(context, friendlyMessage);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await _confirmExit(context);
        if (shouldLeave) {
          context.read<ThiProvider>().reset();
        }
        return shouldLeave;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.deThi.tenDeThi),
          centerTitle: false,
          actions: [
            // Timer Display
            Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _remainingSeconds > 60
                        ? theme.colorScheme.primary
                        : Colors.red.shade600,
                    _remainingSeconds > 60
                        ? theme.colorScheme.secondary
                        : Colors.red.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Consumer<ThiProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3.w),
                    UIHelpers.verticalSpaceMedium(),
                    Text(
                      'Đang tải bài thi...',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return _ErrorView(
                message: provider.error!,
                onRetry: () => provider.startThi(widget.deThi.id),
              );
            }

            final session = provider.currentSession;
            if (session == null || session.cauHois.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.quiz_outlined,
                message: 'Không có câu hỏi để hiển thị',
              );
            }

            if (_remainingSeconds == 0) {
              _startTimer(session.thoiGianThi * 60);
            }

            _currentIndex = _currentIndex.clamp(0, session.cauHois.length - 1);
            final question = session.cauHois[_currentIndex];

            return Column(
              children: [
                _ProgressHeader(
                  current: _currentIndex + 1,
                  total: session.cauHois.length,
                  onJumpTo: (index) => setState(() => _currentIndex = index),
                  questions: session.cauHois,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: _QuestionBody(
                      question: question,
                      questionNumber: _currentIndex + 1,
                      onSelect: (answer) =>
                          _selectAnswer(provider, question, answer),
                    ),
                  ),
                ),
                _QuizControls(
                  canGoBack: _currentIndex > 0,
                  canGoNext: _currentIndex < session.cauHois.length - 1,
                  onBack: () => setState(() => _currentIndex--),
                  onNext: () => setState(() => _currentIndex++),
                  onSubmit: _submitting ? null : () => _submit(provider),
                  isLast: _currentIndex == session.cauHois.length - 1,
                  submitting: _submitting,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectAnswer(
    ThiProvider provider,
    QuizQuestion question,
    String answer,
  ) async {
    await provider.updateDapAn(cauHoiId: question.id, dapAnChon: answer);
    final error = provider.error;
    if (mounted && error != null) {
      UIHelpers.showErrorSnackBar(context, error);
    }
  }

  Future<void> _submit(ThiProvider provider) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    await provider.submitThi();
    setState(() => _submitting = false);
    final result = provider.submitResult;
    if (!mounted || result == null) {
      return;
    }
    _timer?.cancel();
    final ketQuaProvider = context.read<KetQuaThiProvider>();
    final auth = context.read<AuthProvider>();
    final onlyUserId = auth.currentUser?.id;
    unawaited(ketQuaProvider.fetchKetQuaThiList(onlyUserId: onlyUserId));
    provider.reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(deThi: widget.deThi, result: result),
      ),
    );
  }

  void _startTimer(int seconds) {
    if (seconds <= 0) {
      return;
    }
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        final provider = context.read<ThiProvider>();
        _submit(provider);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final minutes = clamped ~/ 60;
    final remaining = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final provider = context.read<ThiProvider>();
    if (provider.currentSession == null) {
      return true;
    }

    final result = await UIHelpers.showConfirmDialog(
      context,
      title: 'Thoát bài thi?',
      message: 'Tiến trình hiện tại sẽ không được lưu.',
      confirmText: 'Thoát',
      cancelText: 'Tiếp tục',
      isDangerous: true,
    );

    return result ?? false;
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final displayMessage = message.length > 300
        ? 'Không thể tải bài thi. Vui lòng thử lại sau.'
        : message;

    return ErrorStateWidget(message: displayMessage, onRetry: onRetry);
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final List<QuizQuestion> questions;
  final ValueChanged<int> onJumpTo;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.questions,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = questions.where((q) => q.selectedAnswer != null).length;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    '$current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              UIHelpers.horizontalSpaceMedium(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu hỏi $current/$total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Đã trả lời: $answered/$total',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          UIHelpers.verticalSpaceMedium(),
          SizedBox(
            height: 48.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final question = questions[index];
                final isAnswered = question.selectedAnswer != null;
                final isCurrent = index == current - 1;

                return GestureDetector(
                  onTap: () => onJumpTo(index),
                  child: Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isCurrent
                          ? null
                          : isAnswered
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.r),
                      border: isCurrent
                          ? null
                          : Border.all(
                              color: isAnswered
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : isAnswered
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final QuizQuestion question;
  final int questionNumber;
  final ValueChanged<String> onSelect;

  const _QuestionBody({
    required this.question,
    required this.questionNumber,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answers = <MapEntry<String, String?>>[
      MapEntry('A', question.dapAnA),
      MapEntry('B', question.dapAnB),
      MapEntry('C', question.dapAnC),
      MapEntry('D', question.dapAnD),
    ].where((entry) => entry.value != null && entry.value!.isNotEmpty);

    return ListView(
      children: [
        // Question Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Câu $questionNumber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                UIHelpers.verticalSpaceMedium(),
                Text(
                  question.noiDung,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        UIHelpers.verticalSpaceMedium(),

        // Answer Options
        Text(
          'Chọn đáp án:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        UIHelpers.verticalSpaceSmall(),

        for (final entry in answers)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Material(
              elevation: question.selectedAnswer == entry.key ? 3 : 1,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                onTap: () => onSelect(entry.key),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: question.selectedAnswer == entry.key
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    gradient: question.selectedAnswer == entry.key
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                              theme.colorScheme.secondary.withValues(
                                alpha: 0.1,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          gradient: question.selectedAnswer == entry.key
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: question.selectedAnswer == entry.key
                              ? null
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: question.selectedAnswer == entry.key
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      UIHelpers.horizontalSpaceMedium(),

                      // Option Text
                      Expanded(
                        child: Text(
                          entry.value!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: question.selectedAnswer == entry.key
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: question.selectedAnswer == entry.key
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),

                      // Check Icon
                      if (question.selectedAnswer == entry.key)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24.sp,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuizControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;
  final bool submitting;

  const _QuizControls({
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
    required this.isLast,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoBack ? onBack : null,
              icon: Icon(Icons.arrow_back, size: 18.sp),
              label: const Text('Trước'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Next/Submit Button
          Expanded(
            flex: isLast ? 2 : 1,
            child: FilledButton.icon(
              onPressed: isLast ? onSubmit : (canGoNext ? onNext : null),
              icon: submitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isLast ? Icons.check_circle_outline : Icons.arrow_forward,
                      size: 18.sp,
                    ),
              label: Text(
                submitting ? 'Đang nộp bài...' : (isLast ? 'Nộp bài' : 'Tiếp'),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: isLast ? Colors.green.shade600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
